package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gocolly/colly/v2"
	goversion "github.com/hashicorp/go-version"

	"github.com/gorilla/mux"
)

var (
	version string
	commit  string
)

func main() {
	println("minectl-fn - bedrock-versions")
	println(version + " " + commit)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("No port specified, defaulting to %s", port)

	}
	r := mux.NewRouter()
	log.Printf("Listening on port %s", port)
	r.HandleFunc("/latest", func(writer http.ResponseWriter, request *http.Request) {
		c := colly.NewCollector()
		latestVersion, _ := goversion.NewVersion("0.0.0")
		c.OnHTML("table.wikitable", func(e *colly.HTMLElement) {
			e.ForEach("th", func(_ int, el *colly.HTMLElement) {
				bedrockVersion, err := goversion.NewVersion(el.Text)
				if err == nil {
					if bedrockVersion.GreaterThan(latestVersion) {
						latestVersion = bedrockVersion
					}
				}

			})
			fmt.Println(latestVersion.Original())
			writeDownloadURL(latestVersion.Original(), writer)
		})
		err := c.Visit("https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server")
		if err != nil {
			http.Error(writer, err.Error(), http.StatusServiceUnavailable)
		}
		/*
			Scraping from GCP is not working, probably they block the IP.
				c := colly.NewCollector()
				c.UserAgent = "minctl"
				c.OnHTML("a[data-platform=serverBedrockLinux]", func(e *colly.HTMLElement) {
					url := e.Attr("href")
					fmt.Println(url)
					writer.WriteHeader(http.StatusOK)
					_, err := writer.Write([]byte(url))
					if err != nil {
						http.Error(writer, err.Error(), http.StatusServiceUnavailable)
					}
				})
				err := c.Visit("https://www.minecraft.net/en-us/download/server/bedrock")
				if err != nil {
					http.Error(writer, err.Error(), http.StatusServiceUnavailable)
				}
		*/
	})
	r.HandleFunc("/binary/{version}", func(writer http.ResponseWriter, request *http.Request) {
		vars := mux.Vars(request)
		version := vars["version"]
		writeDownloadURL(version, writer)
	})
	err := http.ListenAndServe(":"+port, r)
	if err != nil {
		log.Fatal(err)
	}
}

func writeDownloadURL(version string, writer http.ResponseWriter) {
	url := fmt.Sprintf("https://minecraft.azureedge.net/bin-linux/bedrock-server-%s.zip", version)
	res, err := http.Head(url)
	if err != nil {
		http.Error(writer, err.Error(), http.StatusNotFound)
	}
	if res.StatusCode == http.StatusNotFound {
		http.Error(writer, fmt.Sprintf("server binary not found for version %s", version), http.StatusNotFound)
	} else {
		writer.WriteHeader(http.StatusOK)
		_, err := writer.Write([]byte(url))
		if err != nil {
			http.Error(writer, err.Error(), http.StatusServiceUnavailable)
		}
	}
}
