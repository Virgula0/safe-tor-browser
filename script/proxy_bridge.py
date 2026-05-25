import asyncio
import os
import sys
import secrets

USERNAME = "toruser"
PASSWORD = os.environ.get("VNC_PASSWORD", "")
TOR_HOST = "127.0.0.1"
TOR_PORT = 9150

if not PASSWORD:
    template = """=========================================================
🔐 NO VNC PASSWORD PROVIDED. GENERATED FOR SOCKS PROXY: {}
========================================================="""

    PASSWORD = secrets.token_urlsafe(12)
    print(template.format(PASSWORD), file=sys.stdout, flush=True)

async def pipe(reader, writer):
    try:
        while True:
            data = await reader.read(4096)
            if not data:
                break
            writer.write(data)
            await writer.drain()
    except Exception:
        pass
    finally:
        writer.close()

async def handle_client(client_reader, client_writer):
    try:
        # 1. Authenticate SOCKS5 Greeting Protocol
        greeting = await client_reader.readexactly(2)
        version, nmethods = greeting[0], greeting[1]
        if version != 5:
            client_writer.close()
            return

        methods = await client_reader.readexactly(nmethods)
        if 2 not in methods:  # Method 0x02 is Username/Password auth
            client_writer.write(b'\x05\xff')  # Reject connection
            await client_writer.drain()
            client_writer.close()
            return

        # Select Username/Password authentication
        client_writer.write(b'\x05\x02')
        await client_writer.drain()

        # 2. Extract and Validate Credentials
        auth_header = await client_reader.readexactly(2)
        auth_version, ulen = auth_header[0], auth_header[1]
        username = (await client_reader.readexactly(ulen)).decode('utf-8', errors='ignore')

        plen_buf = await client_reader.readexactly(1)
        plen = plen_buf[0]
        password = (await client_reader.readexactly(plen)).decode('utf-8', errors='ignore')

        if username != USERNAME or password != PASSWORD:
            client_writer.write(b'\x01\x01')  # Auth Failure code
            await client_writer.drain()
            client_writer.close()
            return

        client_writer.write(b'\x01\x00')  # Auth Success code
        await client_writer.drain()

        # 3. Read Client Connection Request Payloads
        req_header = await client_reader.readexactly(4)
        ver, cmd, rsv, atyp = req_header[0], req_header[1], req_header[2], req_header[3]

        if atyp == 1:    # IPv4 address allocation
            addr_len = 4 + 2
        elif atyp == 3:  # Domain configuration resolution
            len_buf = await client_reader.readexactly(1)
            addr_len = len_buf[0] + 2
            req_header += len_buf
        elif atyp == 4:  # IPv6 address allocation
            addr_len = 16 + 2
        else:
            client_writer.close()
            return

        rest = await client_reader.readexactly(addr_len)
        socks5_request_payload = req_header + rest

        # 4. Open Communications to Local Tor Agent
        try:
            tor_reader, tor_writer = await asyncio.open_connection(TOR_HOST, TOR_PORT)
        except Exception:
            client_writer.write(b'\x05\x03\x00\x01\x00\x00\x00\x00\x00\x00')  # Host Unreachable
            await client_writer.drain()
            client_writer.close()
            return

        # Handshake sequence to backend Tor engine (Anonymous mode)
        tor_writer.write(b'\x05\x01\x00')
        await tor_writer.drain()

        tor_greeting = await tor_reader.readexactly(2)
        if tor_greeting[0] != 5 or tor_greeting[1] != 0:
            tor_writer.close()
            client_writer.close()
            return

        # Pass target routing instruction payload safely to Tor
        tor_writer.write(socks5_request_payload)
        await tor_writer.drain()

        # Catch Tor's connection outcome header
        tor_response_header = await tor_reader.readexactly(4)
        t_ver, t_rep, t_rsv, t_atyp = tor_response_header[0], tor_response_header[1], tor_response_header[2], tor_response_header[3]

        if t_atyp == 1:
            t_len = 4 + 2
        elif t_atyp == 3:
            t_len_buf = await tor_reader.readexactly(1)
            t_len = t_len_buf[0] + 2
            tor_response_header += t_len_buf
        elif t_atyp == 4:
            t_len = 16 + 2
        else:
            tor_writer.close()
            client_writer.close()
            return

        t_rest = await tor_reader.readexactly(t_len)

        # Mirror Tor connection state status maps back to client context
        client_writer.write(tor_response_header + t_rest)
        await client_writer.drain()

        # 5. Begin Transparent High-Speed Splicing
        await asyncio.gather(
            pipe(client_reader, tor_writer),
            pipe(tor_reader, client_writer)
        )

    except Exception:
        pass
    finally:
        client_writer.close()

async def main():
    server = await asyncio.start_server(handle_client, '0.0.0.0', 5801)
    print("🔒 Authenticated Python SOCKS5 Bridge operational on port 5801.", file=sys.stdout, flush=True)
    async with server:
        await server.serve_forever()

if __name__ == '__main__':
    asyncio.run(main())