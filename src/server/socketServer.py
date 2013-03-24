#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
import threading
import time
import os
import sys
import logging
import logging.handlers
import json
import fcntl
from subprocess import Popen
import socketserver
import traceback
import socket

PROCESS_NAME = 'pythonBus'  # видно в top, htop, ps, etc
PID_FILE_NAME = 'inSide_%s.pid' % PROCESS_NAME

LOG_FILE = './inSide_%s.log' % PROCESS_NAME
LOG_LEVEL = 'DEBUG'

os.chdir(os.path.dirname(os.path.abspath(__file__)))

# LOGGING
try:
    os.makedirs(os.path.split(LOG_FILE)[0])
except OSError:
    pass

# логгер для прокси
bus_handler = logging.handlers.RotatingFileHandler(filename=LOG_FILE, mode='a+', maxBytes=1000000, backupCount=2)
bus_handler.setLevel(getattr(logging, LOG_LEVEL))
bus_handler.setFormatter(logging.Formatter('%(asctime)s\t%(levelname)-8s %(message)s', datefmt='%d.%m.%Y %H:%M:%S'))
logger = logging.getLogger('wtp')
logger.setLevel(logging.DEBUG)
logger.addHandler(bus_handler)

activeServers = []
class BusServer(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    def __init__(self, server_address, handler_class):
        socketserver.TCPServer.__init__(self, server_address, handler_class)

class BusRequestHandler(socketserver.BaseRequestHandler):
    def handle(self):
        # принимаем сигнал
        buf = self.request.recv(1024).decode().replace('\n', '')
        try:
            signal=json.loads(buf)
            # Выполняем обработчики
        except Exception as e:
            logger.error(e)
        finally:
            self.request.close()
class Bus:
    def __init__(self, busName):
        self.connTableCache={}
        self.sighandlers={}
        self.busName=busName

    def start(self):
        # Сервер для получения команд с веба
        self.server = BusServer('/tmp/inSide_%s.sock' % self.busName, BusRequestHandler)
        serverThread = threading.Thread(target=self.server.serve_forever)
        serverThread.start()
        activeServers.append(self.server)

    def send(self, busName, signal):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            print('send to: /tmp/inSide_%s.sock' % busName)
            s.connect('/tmp/inSide_%s.sock' % busName)
            s.send((json.dumps(signal)+"\n").encode())
            s.close()
        except Exception as e:
            traceback.print_exc()
    def parseSignal(self,sigBuffer):
        signal = json.loads(sigBuffer.toString('utf8'))
        if signal['name'] in self.sighandlers:
            for handler in self.sighandlers[signal['name']]:
                self.sighandlers[signal['name']][handler](signal)
    def emit(self, signal):
        connTable = self.loadConnectionTable()
        if signal['name'] in connTable:
            for busName in connTable[signal['name']]:
                if busName != self.busName:
                    self.send(busName, signal)
    def connect(self, signal, handlerName, handler):
        if not signal in self.sighandlers:
            self.sighandlers[signal] = {}
        self.sighandlers[signal][handlerName] = handler
        self.dumpConnectionTable(self.busName)
    def disconnect(self, signal, handlerName):
        del self.sighandlers[signal][handlerName]

    def loadConnectionTable(self):
        try:
            f = open('/tmp/inSide_connectionTable.json', 'r')
            self.connTableCache = json.loads(f.read())
            f.close()
        except Exception as e:
            self.connTableCache = {}
        return self.connTableCache

    def dumpConnectionTable(self, busName):
        connTable = self.loadConnectionTable()
        while True:
            try:
                f = open('/tmp/inSide_connectionTable.json', 'w')
                fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except IOError:
                time.sleep(1)
            else:
                break
        print(json.dumps(connTable))
        for signal in self.sighandlers:
            if not signal in connTable:
                connTable[signal] = {}
            connTable[signal][busName] = {}
            for signal in connTable:
                for bus in connTable[signal]:
                    if bus == busName and signal not in self.sighandlers:
                        del connTable[signal][bus]
                    if not len(connTable[signal].keys()):
                        del connTable[signal]
        f.write(json.dumps(connTable))
        f.close()


def nodaemon():
    """
        Запуск сервера в обычном режиме
    """
    try:
        f = open(PID_FILE_NAME, 'w')
        fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        f.write('%-12i' % os.getpid())
        f.flush()
        bus = Bus('pythonBus')
        bus.connect('test.signal', 'test', lambda s:s)
        bus.start()
        bus.emit({'name': 'test.bus.signal'})

    except Exception as e:
        logger.error(traceback.format_exc())
        exit(0)
    # Циклимся, чтобы не снималась блокировка
    while True:
        time.sleep(10)


def start():
    """
        Запуск сервера в фоновом режиме
    """
    started = already_started()
    if not started:
        try:
            #os.unlink(UNIX_SOCKET_PATH)
            pass
        except:
            pass
        pid = Popen([PROCESS_NAME, os.path.abspath(__file__), 'nodaemon'], executable='python3').pid
    else:
        print('Server already started (pid: %i)' % started)


def stop():
    started = already_started()
    if started:
        # Останавливаем сервера
        for srv in activeServers:
            srv.shutdown()
        os.kill(started, 9)
        print('Server stopped (pid %i)' % started)
    else:
        print('Server not started')
    try:
        pass#os.unlink(UNIX_SOCKET_PATH)
    except:
        pass


def restart():
    stop()
    time.sleep(1)
    start()


def already_started():
    #Если сервер запущен, возвращает pid, иначе 0
    if not os.path.exists(PID_FILE_NAME):
        f = open(PID_FILE_NAME, "w")
        f.write('0')
        f.flush()
        f.close()

    f = open(PID_FILE_NAME, 'r+')
    try:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        started = int(f.read())
    else:
        started = 0
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    f.close()
    return started


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] in (['start', 'stop', 'restart', 'nodaemon']):
        cmd = sys.argv[1]
        globals()[cmd]()
    else:
        print('Error: invalid command')
        print('Usage: python3 socketServer.py {%s}.' % '|'.join(['start', 'stop', 'restart', 'nodaemon']))
