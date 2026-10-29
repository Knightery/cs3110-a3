"""Integration checks against real executables and a pseudo-terminal.
Run after dune build @all: python3 test/terminal_smoke.py
"""
import errno
import os
from pathlib import Path
import pty
import re
import select
import signal
import subprocess
import termios
import time

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / '_build/default/bin/main.exe'
PROBE = ROOT / '_build/default/test/terminal_probe.exe'

def read_until(fd, expected, timeout=4):
    data = b''
    deadline = time.monotonic() + timeout
    while expected not in data and time.monotonic() < deadline:
        if select.select([fd], [], [], max(0, deadline - time.monotonic()))[0]:
            try:
                part = os.read(fd, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not part:
                break
            data += part
    assert expected in data, (expected, data[-500:])
    return data

def terminal_case(action, expected_code, executable=GAME):
    master, slave = pty.openpty()
    before = termios.tcgetattr(slave)
    proc = subprocess.Popen([str(executable), '42'] if executable == GAME else [str(executable)],
                            stdin=slave, stdout=slave, stderr=slave)
    try:
        frame = read_until(master, b'Turns: 0' if executable == GAME else b'READY')
        if executable == GAME:
            assert b'\x1b[1;30;106mC\x1b[0m' in frame, 'camel color missing'
            assert b'\x1b[1;97;41mW\x1b[0m' in frame, 'worm color missing'
        during = termios.tcgetattr(slave)
        assert not during[3] & termios.ICANON
        assert not during[3] & termios.ECHO
        action(proc, master)
        assert proc.wait(timeout=4) == expected_code
        after = termios.tcgetattr(slave)
        # macOS sets transient PENDIN when ICANON is restored; the next
        # terminal read clears it. A Python-only tcsetattr round trip does too.
        transient = getattr(termios, 'PENDIN', 0)
        after[3] &= ~transient
        before[3] &= ~transient
        assert after == before, 'terminal attributes were not restored'
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        os.close(master)
        os.close(slave)

# A wait must advance without Return; an unknown key must not advance.
def play_and_quit(proc, fd):
    os.write(fd, b'z')
    read_until(fd, b'Turns: 0')
    os.write(fd, b'.')
    read_until(fd, b'Turns: 1')
    os.write(fd, b'q')

def cli():
    for value in ['-1', 'abc', '9999999999999999999999999999999', '', '0x2A', '+5', '1_0']:
        result = subprocess.run([str(GAME), value], input=b'q', capture_output=True, timeout=4)
        assert result.returncode == 2
        assert b'nonnegative integer' in result.stderr
    result = subprocess.run([str(GAME), '--help'], capture_output=True, timeout=4)
    assert result.returncode == 0 and b'seed' in result.stdout
    for data in [b'', b'q', b'z.q']:
        result = subprocess.run([str(GAME), '42'], input=data, capture_output=True, timeout=4)
        assert result.returncode == 0, result.stderr
        assert b'Seed: 42' in result.stdout
    # Arrow keys (ESC [ A-D), F2 (ESC O Q) and uppercase letters are
    # unrecognized: every byte redraws, but only the two waits spend turns
    # and nothing quits before the final q.
    ignored = b'\x1b[A\x1b[B\x1b[C\x1b[D\x1bOQWASDQ'
    result = subprocess.run([str(GAME), '42'], input=b'.' + ignored + b'.q',
                            capture_output=True, timeout=4)
    assert result.returncode == 0, result.stderr
    turns = [int(n) for n in re.findall(rb'Turns: (\d+)', result.stdout)]
    assert turns == [0, 1] + [1] * len(ignored) + [2], turns
    result = subprocess.run([str(GAME)], input=b'q', capture_output=True, timeout=4)
    assert result.returncode == 0 and b'Seed:' in result.stdout
    result = subprocess.run([str(GAME), '1', '2'], input=b'q', capture_output=True, timeout=4)
    assert result.returncode == 2

if __name__ == '__main__':
    cli()
    terminal_case(play_and_quit, 0)
    terminal_case(lambda proc, fd: proc.send_signal(signal.SIGINT), 130)
    terminal_case(lambda proc, fd: proc.send_signal(signal.SIGTERM), 143)
    terminal_case(lambda proc, fd: os.write(fd, b'x'), 0, PROBE)
    print('PASS: CLI validation, pipe EOF, immediate keys, quit, SIGINT, SIGTERM, exception cleanup')
