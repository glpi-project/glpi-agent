package main

import (
	// Standard library
	"io"
	"bufio"
	"fmt"
	"os"
	"bytes"
	"log"
	"net/http"
	"crypto/tls"
	"crypto/sha256"
	"strings"

	// Other libraries
	"github.com/jessevdk/go-flags"
)

const version = "0.9"

const useragent = "GLPI-Injector-v"+version

var opts struct {
	Debug bool `long:"debug" description:"debug mode to output server answer"`
	Directory []string `short:"d" long:"directory" description:"load every inventory files from a directory"`
	File []string `short:"f" long:"file" description:"load a specific file"`
	//JsonUA bool `short:"j" long:"json-ua" description:"use Client version found in JSON as User-Agent for POST"`
	MaxDepth int `short:"m" long:"max-depth" description:"maximun depth during directory recursive locading (default: 5)" default:"5"`
	//NoCompression bool `short:"C" long:"no-compression" description:"don't compress sent JSON/XML inventories"`
	NoSSLCheck bool `short:"k" long:"no-ssl-check" description:"do not check server SSL certificate"`
	//Proxy string `short:"P" long:"proxy" description:"http proxy to use"`
	Recursive bool `short:"R" long:"recursive" description:"recursively load inventory files from <directory>"`
	Remove bool `short:"r" long:"remove" description:"remove succesfuly injected files"`
	SSLFingerPrint string `long:"ssl-finger-print" description:"SSL certificate fingerprint validating the server certificate"`
	SSLCertSubject string `long:"ssl-cert-subject" description:"SSL subject to check in SSL server certificate"`
	Stdin bool `long:"stdin" description:"read data from STDIN"`
	Url string `short:"u" long:"url" description:"server URL (mandatory)" required:"yes"`
	UserAgent string `short:"U" long:"useragent" description:"set used HTTP User-Agent for POST"`
	Verbose bool `short:"v" long:"verbose" description:"verbose mode"`
	Version bool `long:"version" description:"show version"`
	//XmlUA bool `short:"x" long:"xml-ua" description:"use Client version found in XML as User-Agent for POST"`
}

var example []string = []string{
	"glpi-injector -v -f /tmp/toto-2010-09-10-11-42-22.json --url https://login:pw@example/",
	"glpi-injector -v -R -d /srv/ftp/fusion --url https://login:pw@example/",
	"",
}

var client *http.Client
var failed []string

func writeExample () {
	fmt.Printf("Example:\n")
	for _, line := range example {
		fmt.Printf("  %s\n", line)
	}
}

func sendContent (client *http.Client, content []byte, what string) ([]byte, error) {

	request, err := http.NewRequest("POST", opts.Url, bufio.NewReader(bytes.NewReader(content)))
	if err != nil {
		return nil, fmt.Errorf("New request error: %v", err)
	}

	// Set request User-Agent
	if opts.UserAgent != "" {
		request.Header.Set("User-Agent", opts.UserAgent)
	} else {
		request.Header.Set("User-Agent", useragent)
	}

	// Tell server to avoid caching our request
	request.Header.Set("Pragma", "no-cache")

	if opts.Verbose {
		fmt.Printf("Sending %s... ", what)
	}

	response, err := client.Do(request)
	if err != nil {
		return nil, fmt.Errorf("Request error: %v", err)
	}

	if opts.Debug {
		fmt.Printf("response status line: %s\n", response.Status)
	} else if opts.Verbose {
		if response.StatusCode >= 400 {
			fmt.Print("HTTP ERROR: ")
		}
		fmt.Println(http.StatusText(response.StatusCode))
	}

	defer response.Body.Close()

	content, err = io.ReadAll(response.Body)

	if response.StatusCode >= 400 {
		err = fmt.Errorf("HTTP ERROR: %s", response.Status)
	}

	return content, err
}

func removeFile (file string) {

	if opts.Verbose {
		fmt.Printf("Deleting %s... ", file)
	}

	err := os.Remove(file)
	if err != nil {
		fmt.Printf("Failed to delete, %v\n", err)
	} else if opts.Verbose {
		fmt.Println("OK")
	}
}

func sendFile (file string) {

	if opts.Verbose {
		fmt.Printf("Loading %s... ", file)
	}

	content, err := os.ReadFile(file)
	if err != nil {
		failed = append(failed, file)
		fmt.Println(err)
		return
	}

	if opts.Verbose {
		fmt.Println("OK")
	}

	if len(content) == 0 {
		content, err = nil, fmt.Errorf("empty file")
		if opts.Remove {
			removeFile(file)
		}
	} else {
		content, err = sendContent(client, content, file)
	}

	if err != nil {
		failed = append(failed, file)
		fmt.Printf("Failed to send %s file: %v\n", file, err)
	} else if opts.Remove {
		removeFile(file)
	}

	if opts.Debug && content != nil {
		fmt.Printf("Answer content: %s\n", content)
	}
}

func sendDirectory (folder string, depth int) {

	if opts.Debug {
		fmt.Printf("Opening folder %s... ", folder)
	}

	entries, err := os.ReadDir(folder)
	if err != nil {
		if ! opts.Debug {
			fmt.Print("Opening folder failure: ")
		}
		fmt.Println(err)
		return
	}

	if opts.Debug {
		fmt.Println("OK")
	}
	for _, entry := range entries {
		path := folder + string(os.PathSeparator) + entry.Name()
		if entry.IsDir() {
			if opts.Recursive && opts.MaxDepth > depth {
				sendDirectory(path, depth+1)
			}
		} else {
			sendFile(path)
		}
	}
}

func main () {

	var tlsconfig *tls.Config
	var disableKeepAlives = false

	log.SetFlags(0)

	args, err := flags.Parse(&opts)

	if flags.WroteHelp(err) {
		writeExample()
		os.Exit(1)
	} else if err != nil {
		os.Exit(1)
	}

	if opts.Version {
		fmt.Println(version)
		os.Exit(0)
	}

	// Always enable verbose mode if debug is enabled
	if opts.Debug {
		opts.Verbose = true
	}

	// Handle SSL options
	if opts.NoSSLCheck {
		tlsconfig = &tls.Config{
			InsecureSkipVerify: true,
		}
	} else if opts.SSLCertSubject != "" {
		tlsconfig = &tls.Config{
			InsecureSkipVerify: true,
			VerifyConnection: func(cs tls.ConnectionState) error {
				if len(cs.PeerCertificates) == 0 {
					return fmt.Errorf("No server certificate found on connection")
				}
				cn := cs.PeerCertificates[0].Subject.String()
				if cn != opts.SSLCertSubject {
					return fmt.Errorf("Certificate CN mismatch: found '%s'", cn)
				}
				return nil
			},
		}
	} else if opts.SSLFingerPrint != "" {
		tlsconfig = &tls.Config{
			InsecureSkipVerify: true,
			VerifyConnection: func(cs tls.ConnectionState) error {
				if len(cs.PeerCertificates) == 0 {
					return fmt.Errorf("No server certificate found on connection")
				}
				fingerprint := fmt.Sprintf("%x", sha256.Sum256(cs.PeerCertificates[0].Raw))
				if fingerprint != opts.SSLFingerPrint {
					return fmt.Errorf("SSL certificate fingerprint mismatch: found '%s'", fingerprint)
				}
				return nil
			},
		}
	}

	if opts.Stdin {
		disableKeepAlives = true
	}

	tr := &http.Transport{
		DisableKeepAlives:  disableKeepAlives,
		TLSClientConfig:    tlsconfig,
	}

	// Setup http client
	client = &http.Client{Transport: tr}

	if opts.Stdin {
		var content []byte
		content, err = io.ReadAll(bufio.NewReader(os.Stdin))
		if err != nil {
			log.Fatalf("Failed to read stdin: %v\n", err)
		}
		if opts.Verbose {
			fmt.Printf("Read %d bytes on stdin\n", len(content))
		}
		_, err = sendContent(client, content, "stdin")
		if err != nil {
			log.Fatalf("Failed to send stdin: %v\n", err)
		}
	} else if opts.File != nil {
		if args != nil {
			opts.File = append(opts.File, args...)
		}
		for _, file := range opts.File {
			sendFile(file)
		}
	} else if opts.Directory != nil {
		if args != nil {
			opts.Directory = append(opts.Directory, args...)
		}
		for _, folder := range opts.Directory {
			sendDirectory(folder, 0)
		}
	} else {
		fmt.Println("Nothing to do\n")
		flags.ParseArgs(&opts, []string{"--help",})
		writeExample()
		os.Exit(1)
	}

	if failed != nil {
		message := "\nFile"
		if len(failed) > 1 {
			message += "s"
		}
		message += " not sent: "
		log.Fatalf(message + strings.Join(failed, " "))
	}
}
