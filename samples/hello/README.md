# hello — sample plugin

Minimal `hypr` plugin for the POC: binds `SUPER + SHIFT + H` to a desktop
notification through the injected SDK.

Install (user dir — zero `dots` changes):

```sh
mkdir -p ~/.config/hypr/plugins-user
cp -r . ~/.config/hypr/plugins-user/hello
```

Then enable it in Settings → Plugins (or `dots plugins enable hello`) and
press `SUPER + SHIFT + H`. Disable it and the bind is gone on the next
config reload.
