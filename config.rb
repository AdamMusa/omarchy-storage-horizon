# frozen_string_literal: true

OmarchyUI.configure do
  type :plugin
  id "izeesoft.storage-horizon"
  name "Storage Horizon"
  slug "storage-horizon"
  version "0.1.0"
  author "Adam Moussa Ali"
  license "MIT"
  description "Per-mount storage growth history with projected exhaustion horizons."
  entrypoint "main.rb"

  bar_widget do
    display_name "Storage Horizon"
    description "See when disks are filling, not only how full they are now."
    category "System"
    default_section :right
  end
end
