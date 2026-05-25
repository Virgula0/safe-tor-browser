# Safe Tor Brower

Run a tor browser instance within a containerized environment

# Run

Set your own password passing an env variable `export VNC_PASSWORD=MySuperSecurePassword` or leave empty to auto-generate it.

If password is autogenerate you need to run `docker compose logs tor-browser` to view your password.

```bash
docker compose up --build -d
```

If you want to check logs:

```bash
docker logs tor-browser -f
```

Visit `http://10.9.0.1:5800` on your browser.
If you want to rescale the size of the window visit: `http://10.9.0.1:5800/?resize=scale`

## Launch app

1. Right click on black background
2. Launch `Tor Browser` or `XTerm`

## List supported env variables

- `HOST_ADDRESS` -> change listening host address, default is `127.0.0.1`
- `VNC_PASSWORD` -> set custom password to access vnc. Default is randomly generated.