package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-resty/resty/v2"
	"github.com/gorilla/mux"
)

var (
	version string
	commit  string
)

type JavaManifest struct {
	Latest struct {
		Release  string `json:"release"`
		Snapshot string `json:"snapshot"`
	} `json:"latest"`
	Versions []struct {
		ID          string    `json:"id"`
		Type        string    `json:"type"`
		URL         string    `json:"url"`
		Time        time.Time `json:"time"`
		ReleaseTime time.Time `json:"releaseTime"`
	} `json:"versions"`
}

type MinecraftBinaryDetails struct {
	Downloads struct {
		Server struct {
			Sha1 string `json:"sha1"`
			Size int    `json:"size"`
			URL  string `json:"url"`
		} `json:"server"`
	} `json:"downloads"`
	ID          string `json:"id"`
	JavaVersion struct {
		Component    string `json:"component"`
		MajorVersion int    `json:"majorVersion"`
	} `json:"javaVersion"`
	ReleaseTime time.Time `json:"releaseTime"`
	Time        time.Time `json:"time"`
	Type        string    `json:"type"`
}

type MinectlFN struct {
	port string
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("No port specified, defaulting to %s", port)

	}
	minectlFN := &MinectlFN{
		port,
	}
	minectlFN.Initialize()
}

func getServerUrl(app *MinectlFN, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	version := vars["version"]

	client := resty.New()

	resp, err := client.R().Get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
	javaManifest := JavaManifest{}
	if err := json.Unmarshal(resp.Body(), &javaManifest); err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
	for _, item := range javaManifest.Versions {
		if version == item.ID {
			resp, err := client.R().Get(item.URL)
			if err != nil {
				http.Error(w, err.Error(), http.StatusServiceUnavailable)
			}
			minecraftBinaryDetails := MinecraftBinaryDetails{}
			if err := json.Unmarshal(resp.Body(), &minecraftBinaryDetails); err != nil {
				http.Error(w, err.Error(), http.StatusServiceUnavailable)
			}
			_, err = w.Write([]byte(minecraftBinaryDetails.Downloads.Server.URL))
			if err != nil {
				http.Error(w, err.Error(), http.StatusServiceUnavailable)
			}

		}
	}
}

func getServerVersion(app *MinectlFN, w http.ResponseWriter, r *http.Request) {
	client := resty.New()

	resp, err := client.R().Get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
	javaManifest := JavaManifest{}
	if err := json.Unmarshal(resp.Body(), &javaManifest); err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
	_, err = w.Write([]byte(javaManifest.Latest.Release))
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
}

func (app *MinectlFN) Initialize() {
	println("minectl-fn - java-version")
	println(version + " " + commit)
	r := mux.NewRouter()
	r.HandleFunc("/latest", app.handleRequest(getServerVersion))
	r.HandleFunc("/binary/{version}", app.handleRequest(getServerUrl))

	log.Printf("Listening on port %s", app.port)

	err := http.ListenAndServe(":"+app.port, r)
	if err != nil {
		log.Fatal(err)
	}
}

type RequestHandlerFunction func(app *MinectlFN, w http.ResponseWriter, r *http.Request)

func (app *MinectlFN) handleRequest(handler RequestHandlerFunction) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(app, w, r)
	}
}
