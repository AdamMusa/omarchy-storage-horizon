# source: main.rb
# frozen_string_literal: true


# source: lib/backend.rb
# frozen_string_literal: true

class SuiteBackend
  SCORE_LABEL = "mounts"
  STATUSES = ["open", "tending", "complete"].freeze
  MAX_ITEMS = 128
  MAX_HISTORY = 256
  MAX_TEXT = 512
  MAX_STATE_BYTES = 262_144
  OUTPUT_LIMIT = 65_536

  Result = Struct.new(:stdout, :stderr, :exitstatus) do
    def success? = exitstatus.to_i.zero?
  end

  attr_reader :records

  def initialize(state_dir: File.expand_path("~/.local/state/omarchy-storage-horizon"), runner: nil)
    @state_dir = state_dir
    @state_path = File.join(state_dir, "state.json")
    @runner = runner
    @records = []
    @history = []
    @settings = {}
    @summary = "Starting"
    @score = 0
    create_directory(@state_dir)
    load_state
  end

  def snapshot
    {
      "items" => @records.first(MAX_ITEMS),
      "history" => @history.last(MAX_HISTORY),
      "summary" => clean(@summary, 100),
      "score" => @score.to_i,
      "updated_at" => Time.now.to_i
    }
  end

  def add(primary, secondary = "")
    title = clean(primary)
    detail = clean(secondary)
    return snapshot if title.empty?
    record = {
      "id" => "#{Time.now.to_i}-#{rand(1_000_000)}",
      "title" => title,
      "detail" => detail,
      "status" => STATUSES.first,
      "meta" => Time.now.strftime("%Y-%m-%d %H:%M")
    }
    after_add(record)
    @records.unshift(record)
    @records = @records.first(MAX_ITEMS)
    @score = @records.length
    @summary = "#{@records.length} #{SCORE_LABEL}"
    persist
    snapshot
  end

  def act(id)
    record = @records.find { |candidate| candidate["id"] == id.to_s }
    return snapshot unless record
    current = STATUSES.index(record["status"]) || 0
    record["status"] = STATUSES[(current + 1) % STATUSES.length]
    record["meta"] = "Updated #{Time.now.strftime("%Y-%m-%d %H:%M")}"
    persist
    snapshot
  end

  def remove(id)
    @records.reject! { |candidate| candidate["id"] == id.to_s }
    @score = @records.length
    @summary = @records.empty? ? "Ready" : "#{@records.length} #{SCORE_LABEL}"
    persist
    snapshot
  end

  def refresh
    scanned = scan_system
    @records = scanned if scanned.is_a?(Array)
    @records = @records.first(MAX_ITEMS)
    persist
    snapshot
  rescue StandardError => error
    @summary = "Needs attention"
    @records.unshift(item("Refresh issue", clean(error.message, 180), "inspect", "No system state was changed"))
    @records = @records.first(MAX_ITEMS)
    snapshot
  end

  private

  def after_add(record)
    record["status"] = STATUSES.first
    record
  end

  def scan_system
    lines = command_text(["df", "-P", "-B1"]).lines.drop(1).first(64)
    points = @settings["mount_points"].is_a?(Hash) ? @settings["mount_points"] : {}
    rows = lines.filter_map do |line|
      fields = line.split
      next if fields.length < 6
      total, used, mount = fields[1].to_i, fields[2].to_i, fields[5]
      next if total <= 0
      history = points[mount].is_a?(Array) ? points[mount] : []
      history << [Time.now.to_i, used]
      history = history.last(96)
      points[mount] = history
      delta_time = history.length > 1 ? history.last[0] - history.first[0] : 0
      growth = history.length > 1 ? history.last[1] - history.first[1] : 0
      seconds = growth > 0 && delta_time > 0 ? (total - used) * delta_time / growth : nil
      horizon = seconds && seconds.positive? ? "full in ~#{human_duration(seconds)}" : "no growth forecast yet"
      item(mount, "#{percent(used, total)}% used · #{horizon}", percent(used, total) >= 90 ? "tight" : "observing", human_bytes(total - used) + " free")
    end
    @settings["mount_points"] = points.to_a.last(32).to_h
    @score = rows.length
    @summary = rows.empty? ? "No mounts" : "#{rows.length} horizons"
    rows
  end

  def item(title, detail, status = "observed", meta = "")
    {
      "id" => fnv1a("#{title}:#{detail}:#{status}"),
      "title" => clean(title), "detail" => clean(detail),
      "status" => clean(status, 80), "meta" => clean(meta, 240)
    }
  end

  def run(argv, timeout: 8)
    return @runner.call(argv, timeout: timeout) if @runner
    OmarchyUI::Command.run(argv, timeout: timeout, max_output_bytes: OUTPUT_LIMIT)
  rescue Errno::ENOENT, OmarchyUI::CommandTimeout, OmarchyUI::CommandOutputLimit
    nil
  end

  def command_text(argv, timeout: 8)
    result = run(argv, timeout: timeout)
    return "" unless result && result.success?
    clean(result.stdout.to_s, OUTPUT_LIMIT)
  end

  def parse_json(text)
    return nil if text.nil? || text.empty? || text.bytesize > OUTPUT_LIMIT
    JSON.parse(text)
  rescue JSON::ParserError
    nil
  end

  def clean(value, limit = MAX_TEXT)
    value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "�").byteslice(0, limit).to_s
  rescue StandardError
    value.to_s.byteslice(0, limit).to_s
  end

  def safe_read(path, limit = MAX_STATE_BYTES)
    return nil unless File.file?(path)
    File.open(path, "rb") do |file|
      data = file.read(limit + 1)
      return nil if data && data.bytesize > limit
      data
    end
  rescue SystemCallError
    nil
  end

  def relative_files(root)
    return [] unless File.directory?(root)
    result = []
    queue = [[root, ""]]
    until queue.empty? || result.length >= 2_000
      absolute, relative = queue.shift
      Dir.children(absolute).sort.first(512).each do |entry|
        next if entry == ".git" || entry == "node_modules" || entry == "vendor"
        child = File.join(absolute, entry)
        rel = relative.empty? ? entry : File.join(relative, entry)
        if File.directory?(child) && !File.symlink?(child)
          queue << [child, rel]
        elsif File.file?(child)
          result << rel
        end
      rescue SystemCallError
        next
      end
    end
    result
  end

  def executable?(name)
    return false if name.to_s.include?(File::SEPARATOR)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
      path = File.join(directory, name.to_s)
      File.respond_to?(:executable?) ? File.executable?(path) : File.file?(path)
    end
  end

  def secure_equal?(left, right)
    return false unless left.bytesize == right.bytesize
    difference = 0
    left.bytes.zip(right.bytes) { |a, b| difference |= a ^ b }
    difference.zero?
  end

  def fnv1a(value)
    hash = 2_166_136_261
    value.to_s.each_byte { |byte| hash = ((hash ^ byte) * 16_777_619) & 0xffff_ffff }
    format("%08x", hash)
  end

  def percent(part, whole)
    return 0 if whole.to_i <= 0
    [[(part.to_f / whole.to_f * 100).round, 0].max, 100].min
  end

  def human_bytes(bytes)
    value = bytes.to_f
    units = %w[B KiB MiB GiB TiB]
    unit = units.shift
    while value >= 1024 && !units.empty?
      value /= 1024.0
      unit = units.shift
    end
    "#{value.round(value >= 10 ? 0 : 1)} #{unit}"
  end

  def human_duration(seconds)
    days = seconds.to_f / 86_400
    return "#{days.round} days" if days < 365
    "#{(days / 365).round(1)} years"
  end

  def short_path(path)
    home = File.expand_path("~")
    path.start_with?(home) ? path.sub(home, "~") : path
  end

  def create_directory(path)
    current = path.start_with?(File::SEPARATOR) ? File::SEPARATOR : ""
    path.split(File::SEPARATOR).each do |part|
      next if part.empty?
      current = File.join(current, part)
      Dir.mkdir(current, 0o700) unless File.directory?(current)
    end
  end

  def load_state
    return unless File.file?(@state_path) && !File.symlink?(@state_path)
    data = safe_read(@state_path)
    parsed = data ? JSON.parse(data) : {}
    @records = Array(parsed["records"]).filter_map { |record| normalize_record(record) }.first(MAX_ITEMS)
    @history = Array(parsed["history"]).select { |entry| entry.is_a?(Hash) }.last(MAX_HISTORY)
    @settings = parsed["settings"].is_a?(Hash) ? parsed["settings"] : {}
    @score = @records.length
    @summary = @records.empty? ? "Ready" : "#{@records.length} #{SCORE_LABEL}"
  rescue JSON::ParserError, SystemCallError
    @records = []; @history = []; @settings = {}
  end

  def normalize_record(record)
    return nil unless record.is_a?(Hash)
    title = clean(record["title"])
    return nil if title.empty?
    {
      "id" => clean(record["id"], 80), "title" => title,
      "detail" => clean(record["detail"]), "status" => clean(record["status"], 80),
      "meta" => clean(record["meta"], 240), "evidence" => record["evidence"].is_a?(Hash) ? record["evidence"] : nil
    }.compact
  end

  def persist
    payload = JSON.generate("records" => @records.first(MAX_ITEMS), "history" => @history.last(MAX_HISTORY), "settings" => @settings)
    raise "state exceeds safety limit" if payload.bytesize > MAX_STATE_BYTES
    temporary = "#{@state_path}.tmp-#{Process.pid}-#{rand(1_000_000)}"
    File.open(temporary, "w", 0o600) { |file| file.write(payload) }
    File.rename(temporary, @state_path)
  ensure
    File.delete(temporary) if temporary && File.file?(temporary)
  end
end


backend = SuiteBackend.new

OmarchyUI.plugin do
  state :snapshot, backend.snapshot
  state :primary, ""
  state :secondary, ""
  state :compose, false

  refresh = proc do
    state.snapshot = backend.refresh
  rescue StandardError
    state.snapshot = backend.snapshot
  end

  status_color = lambda do |status|
    value = status.to_s.downcase
    if value.match?(/broken|critical|missing|mismatch|drift|inactive|slow|tight|hotspot|invalid/)
      "#ff6b78"
    elsif value.match?(/ready|valid|verified|finished|aligned|unique|internal|familiar|steady|covered|available|detected|normal/)
      "#a29bfe"
    else
      "#efc66b"
    end
  end

  status_icon = lambda do |status|
    value = status.to_s.downcase
    if value.match?(/broken|critical|missing|mismatch|drift|inactive|slow|tight|hotspot|invalid/)
      :warning
    elsif value.match?(/ready|valid|verified|finished|aligned|unique|internal|familiar|steady|covered|available|detected|normal/)
      :circle_check
    else
      :circle_info
    end
  end

  bar_widget do
    row spacing: 7 do
      icon :folder, color: "#a29bfe"
      text { state.snapshot.fetch("summary") }
    end
    on_click { open_panel :storage_horizon }
  end

  panel :storage_horizon do
    scroll width: 660, height: 760 do
      dynamic id: :scene, spacing: 16 do
        entries = state.snapshot.fetch("items")
        history = state.snapshot.fetch("history")

        row spacing: 12 do
          icon :folder, size: 30, color: "#a29bfe"
          column spacing: 2 do
            text "Storage Horizon", style: :heading, width: 500
            text state.snapshot.fetch("summary"), style: :caption, width: 500
          end
          action_button :refresh, tooltip: "Refresh", foreground: "#a29bfe" do
            async(&refresh)
          end
        end

        separator
        section_header "Filesystem horizons"
            if entries.empty?
              column spacing: 8 do
                        icon :folder, size: 34, color: "#a29bfe"
                        text "Nothing to show yet", style: :heading
                        text "Mounted filesystems will appear with usage and growth forecasts.", style: :caption, wrap: true, width: 560
                      end
            else
              entries.first(12).each_with_index do |entry, index|
                percent_used = entry.fetch("detail", "")[/d+/].to_i
                column spacing: 6 do
                  row spacing: 8 do
                    icon :folder, color: status_color.call(entry.fetch("status", ""))
                    text entry.fetch("title"), style: :heading, width: 380
                    text "#{percent_used}%", color: status_color.call(entry.fetch("status", "")), width: 54
                    text entry.fetch("meta", ""), style: :caption, width: 110
                  end
                  progress(percent_used, width: 590, height: 5, color: status_color.call(entry.fetch("status", "")))
                  text entry.fetch("detail", "").sub(/^d+% used · /, ""), style: :caption
                end
                separator unless index == [entries.length, 12].min - 1
              end
            end
      end
    end
  end

  after(0.08, &refresh)
  every(300, &refresh)
end
