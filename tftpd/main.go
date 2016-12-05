package main

import (
	"fmt"
	"github.com/docopt/docopt-go"
	"go.universe.tf/netboot/tftp"
	"log"
	"net"
	"path/filepath"
)

const (
	portTFTP     = 69
	MaxBlockSize = 1468
)

func infoLog(m string) {
	log.Printf("TFTP server log: %s\n", m)
}

func transferLog(a net.Addr, p string, e error) {
	extra := ""
	if e != nil {
		extra = "(" + e.Error() + ")"
	}
	log.Printf("TFTP server transferred %q to %s %s\n", p, a, extra)
}

func main() {
	usage := `
Usage:
  tftpd [options] <path>

Options:
  -i --iface=<iface>   Specify an interface to use.
  -h --help            Show this screen.
  -v --version         Show version.
`
	arguments, err := docopt.Parse(usage, nil, true, "tftpd 1.0", false)
	if err != nil {
		log.Fatalf("Error %s", err)
	}

	file_path, err := filepath.Abs(arguments["<path>"].(string))
	if err != nil {
		log.Fatalf("Error %s: %s", file_path, err)
	}

	iface_name := "all ifaces"
	iface_ip := ""
	if arguments["--iface"] != nil {
		iface_name = arguments["--iface"].(string)
		iface, err := net.InterfaceByName(iface_name)
		if err != nil {
			log.Fatalf("Error: %s: %s", iface_name, err)
		}
		iface_addrs, err := iface.Addrs()
		if err != nil {
			log.Fatalf("Error: %s", err)
		}

		// We take the first IP to be the good one, it's a simple tool
		// after all.
		main_iface_ip, _, err := net.ParseCIDR(iface_addrs[0].String())
		if err != nil {
			log.Fatalf("Error: %s", err)
		}
		iface_ip = main_iface_ip.String()
	}

	handler, err := tftp.FilesystemHandler(file_path)
	if err != nil {
		log.Fatalf("Error: %s", err)
	}

	ts := tftp.Server{
		Handler:      handler,
		InfoLog:      infoLog,
		TransferLog:  transferLog,
		MaxBlockSize: MaxBlockSize,
	}

	address := fmt.Sprintf("%s:%d", iface_ip, portTFTP)
	log.Printf("Serving %s from %s (%s)", file_path, address, iface_name)
	tftp, err := net.ListenPacket("udp", address)
	if err != nil {
		fmt.Errorf("TFTP server shut down: %s", err)
	}

	err = ts.Serve(tftp)
	if err != nil {
		fmt.Errorf("TFTP server shut down: %s", err)
	}
	tftp.Close()
}
