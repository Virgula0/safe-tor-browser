# Safe Tor Brower

Run a tor browser instance within a containerized environment

# Run

```bash
docker compose up --build -d
```

If you want to check logs: 

```bash
docker logs tor-browser -f
```

Visit `http://10.9.0.1:5800` on your browser.
If you want to rescale the size of the window visit: `http://10.9.0.1:5800/?resize=scale`

### Launch app

1. Right click on black background
2. Launch `Tor Browser` or `XTerm`