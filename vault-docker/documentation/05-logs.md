[Retour menu principal](../README.md)

# 5. Logs
## Audit logs

To enable an audit device, execute the `vault audit enable` command.

```console
/vault # vault audit enable file file_path=/vault/logs/vault-audit.log
Success! Enabled the file audit device at: file/
```

if you need to disable just run the following command :

```console
/ # vault audit disable file
Success! Disabled audit device (if it was enabled) at: file/
```

You can also use vault audit list -detailed to get the full path for audit device options.

```console
/vault # vault audit list -detailed
Path     Type    Description    Replication    Options
----     ----    -----------    -----------    -------
file/    file    n/a            replicated     file_path=/vault/logs/vault-audit.log
```

## Server logs

To enable server logs, you need to configure it in your `vault.json` config file by adding the line `log_level = "<log-level>"`. Log level can be :

- trace
- debug
- info
- warn
- err

Default is `info`.

If you change the log level, you need to restart Vault to take changes into account.

To consult logs, just execute following command :

```
docker logs vault
```