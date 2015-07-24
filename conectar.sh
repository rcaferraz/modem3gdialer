#!/usr/bin/python
# -*- coding: iso-8859-1 -*-

import Tkinter
import socket
import threading
import subprocess
import time


class simpleapp_tk(Tkinter.Tk):
    def __init__(self,parent):
        Tkinter.Tk.__init__(self,parent)
        self.parent = parent
        self.initialize()

    def initialize(self):
        self.grid()

        self.button = Tkinter.Button(self,text=u"Conectar",
                                command=self.OnButtonClick)
        self.button.grid(column=0,row=0,sticky='EW')

        self.statusLabelVariable = Tkinter.StringVar()
        self.statusLabel = Tkinter.Label(self,textvariable=self.statusLabelVariable,
                              anchor="w",fg="black",bg="white")
        self.statusLabel.grid(column=0,row=1,sticky='S')
        self.statusLabelVariable.set(u"---")

        self.onlineLabelVariable = Tkinter.StringVar()
        self.onlineLabel = Tkinter.Label(self,textvariable=self.onlineLabelVariable,
                              anchor="w",fg="black",bg="white")
        self.onlineLabel.grid(column=0,row=2,sticky='S')
        self.onlineLabelVariable.set(u"---")

        self.grid_columnconfigure(0,weight=1)
        self.resizable(True,False)
        self.update()
        self.geometry(self.geometry())

        t = threading.Thread(target=self.update_connection_status)
        t.setDaemon(True)
        t.start()
        t = threading.Thread(target=self.update_plog_status)
        t.setDaemon(True)
        t.start()
        self.button_timer = 0
        t = threading.Thread(target=self.disable_button)
        t.setDaemon(True)
        t.start()
        

    def OnButtonClick(self):
        t = threading.Thread(target=self.run_pon)
        t.setDaemon(True)
        t.start()

    def follow(self, thefile):
        thefile.seek(0,2)
        while True:
            line = thefile.readline()
            if not line:
                time.sleep(0.1)
                continue
            yield line

    def update_plog_status(self):
        logfile = open("/var/log/syslog","r")
        loglines = self.follow(logfile)
        for line in loglines:
            message = self.convert_syslog_to_message(line)
            if self.onlineLabelVariable.get() == "Conectado":
                message = "OK"
            if message is not None:
                self.statusLabelVariable.set(message)

    def convert_syslog_to_message(self, line):
        if "pppd" in line or "chat" in line:
            if "unrecognized option '/dev/ttyUSB0'" in line:
                self.increase_button_timer(5)
                return "Modem desconectado. Coloque-o novamente."
            elif "ERROR^M" in line:
                self.increase_button_timer(50)
                return "Erro ao conectar. Aguarde."
            elif "Exit" in line:
                self.increase_button_timer(20)
                return "Escolha a conexao Vivo e tente novamente."
            elif "Script /etc/ppp/ip-up finished" in line:
                return "OK"
            else:
                self.increase_button_timer(20)
                return "Aguarde ou tente novamente."
        elif "D-Link DWM-156" in line:
            self.increase_button_timer(20)
            return "Modem conectado. Escolha a conexao Vivo e aguarde."

    def update_connection_status(self):
        while True:
            connection_status = self.is_connected()
            if connection_status:
                self.onlineLabel.config(bg="green")
                self.onlineLabelVariable.set("Conectado")
                self.statusLabelVariable.set("OK")
                self.button.config(state="disabled")
            else:
                self.onlineLabel.config(bg="red")
                self.onlineLabelVariable.set("Desconectado")
                #self.enable_button()
            time.sleep(0.1)
                
    def disable_button(self):
        while True:
            if self.button_timer > 0:
                self.button.config(state="disabled")
                start_time = time.time()
                elapsed_time = 0
                while elapsed_time < self.button_timer:
                    elapsed_time = time.time() - start_time
                    self.button.config(text="Conectar ("+str(int(self.button_timer - elapsed_time))+")")
                self.button_timer = 0
                self.button.config(text="Conectar")
                self.enable_button()

    def enable_button(self):
        self.button.config(state="normal")

    def increase_button_timer(self, seconds):
        self.button_timer = self.button_timer + seconds
        if self.button_timer > 70:
            self.button_timer = 70    

    def is_connected(self):
        REMOTE_SERVER = "www.google.com"
        try:
          # see if we can resolve the host name -- tells us if there is
          # a DNS listening
          host = socket.gethostbyname(REMOTE_SERVER)
          # connect to the host -- tells us if the host is actually
          # reachable
          s = socket.create_connection((host, 80), 2)
          return True
        except:
           pass
        return False

    def run_pon(self):
        proc = subprocess.Popen(['sudo','pon'])

if __name__ == "__main__":
    app = simpleapp_tk(None)
    app.title('Conectar na Internet')
    app.geometry('{}x{}'.format(350, 70))
    app.mainloop()

