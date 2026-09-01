# Compiled QML provenance

Omarchy UI generated this package's native Qt module from the tree-shaken Zui and
Omarchy host QML graph. The exact generated source graph and CMake build definition are
retained in `qml-source/` for independent audit and byte-for-byte reproduction.

- Format: `qt-aot-qml-module` version 1
- Qt: `6.11.2`
- Module: `OmarchyUI.Bundles.Bf99be4fb7f1c6b7c992b`
- Source fingerprint: `f99be4fb7f1c6b7c992bb3be689f92c5a531a66d4543f2b785af686b11d7de86`

## Artifacts

- `OmarchyUI/Bundles/Bf99be4fb7f1c6b7c992b/libomarchy_ui_bundle_bf99be4fb7f1c6b7c992b.so` — `689eddd6d2d25d09ca351a5faf857304ee28f75368673e8bf90518f19385b47b`
- `OmarchyUI/Bundles/Bf99be4fb7f1c6b7c992b/libomarchy_ui_bundle_bf99be4fb7f1c6b7c992bplugin.so` — `93b5b4585c6920ed5fe812cf1fc454a16d202d3fe4c0081fbceb3d42fe0a7fa6`

Verify the packaged libraries from the plugin directory:

```bash
sha256sum --check omarchy-ui-qml-bundle.sha256
```

Rebuild the checked-in libraries from the retained sources and compare every byte:

```bash
scripts/rebuild-qml-bundle.sh
```

The pinned toolchain, CI process, and GitHub artifact-attestation flow are documented in
[`REPRODUCIBLE_BUILD.md`](REPRODUCIBLE_BUILD.md).

`Service.qml`, `Panel.qml`, and `BarWidget.qml` are the minimal loader shims required for the
plugin kinds declared in `manifest.json`. Application UI lives in the compiled
module recorded by `omarchy-ui-qml-bundle.json`.
