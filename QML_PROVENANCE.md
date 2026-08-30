# Compiled QML provenance

Omarchy UI generated this package's native Qt module from the tree-shaken Zui and
Omarchy host QML graph. Generated QML source contents were discarded after AOT compilation.

- Format: `qt-aot-qml-module` version 1
- Qt: `6.11.2`
- Module: `OmarchyUI.Bundles.B1bbe3e8534cebed13c9d`
- Source fingerprint: `1bbe3e8534cebed13c9dcea44de4b1cf36eff72631e3298efeb1fb23704baad3`

## Artifacts

- `OmarchyUI/Bundles/B1bbe3e8534cebed13c9d/libomarchy_ui_bundle_b1bbe3e8534cebed13c9d.so` — `c29139e0ca1aa74418d8681bb0d31a4a231f706e6bcbe55a11fcbfbe5e4fdabf`
- `OmarchyUI/Bundles/B1bbe3e8534cebed13c9d/libomarchy_ui_bundle_b1bbe3e8534cebed13c9dplugin.so` — `fa6573c56660eb5db7fc3ed82647c0a02e8161c5a9843d7094a46c40752bfdbe`

Verify the packaged libraries from the plugin directory:

```bash
sha256sum --check omarchy-ui-qml-bundle.sha256
```

`App.qml`, `Service.qml`, `Panel.qml`, and `BarWidget.qml` are the minimal loader shims
required by Omarchy's file-based entry-point contract. Application UI lives in the compiled
module recorded by `omarchy-ui-qml-bundle.json`.
