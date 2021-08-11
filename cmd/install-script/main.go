package main

import (
	_ "embed"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

var (
	version string
	commit  string
)

//go:embed install.sh
var installShell string

func main() {
	println("minectl-fn - install-script")
	println(version + " " + commit)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("No port specified, defaulting to %s", port)

	}
	r := mux.NewRouter()
	log.Printf("Listening on port %s", port)
	r.HandleFunc("/", func(writer http.ResponseWriter, request *http.Request) {
		_, err := writer.Write([]byte(installShell))
		if err != nil {
			http.Error(writer, err.Error(), http.StatusServiceUnavailable)
		}
	})
	r.HandleFunc("/install.ps1", func(writer http.ResponseWriter, request *http.Request) {

	})
	err := http.ListenAndServe(":"+port, r)
	if err != nil {
		log.Fatal(err)
	}
}
