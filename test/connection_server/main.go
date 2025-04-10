package main

import (
	"log"

	"github.com/khulnasoft/khulnasoft/pkg/commands"
	"github.com/khulnasoft/khulnasoft/pkg/tcp"
	"github.com/khulnasoft/khulnasoft/pkg/testies"
)

func main() {
	testies.SetupLogger()
	server, err := testies.CreateServerFromArgs()

	if err != nil {
		log.Fatal("errror could not start", err)
	}

	defer server.Close()

	commander := commands.NewCommander()
	server.WelcomeMessage(func() *tcp.TCPCommand { return commander.ToCommands() })

	log.Printf("starting server\n")

	go server.Start()

	for {
		cmd := <-server.FromSockets
		server.Send(cmd.Command)
	}
}
