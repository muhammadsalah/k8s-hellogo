/*Hellogo is a simple http webserver program that replies with hello go message, and has
the ability of creating a forward http get request of a defined service in the process environment
variables*/
package main

import (
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

/*URL for the chained service*/
var CHAIN_URL string

func main() {
	CHAIN_URL = os.Getenv("CHAIN_URL")
	r := http.NewServeMux()
	r.Handle("/", index())
	r.Handle("/health", healthz())
	http.Handle("/", r)
	if err := http.ListenAndServe(":8000", nil); err != nil {
		panic(err)
	}
}
/*Root handler for a basic webserver route*/
func index () http.Handler {
	return http.HandlerFunc(func (w http.ResponseWriter, r *http.Request) {
		/*Only root path is allowed*/
		if r.URL.Path != "/" {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			log.Printf("[INFO] Server responded with: [%v] and status: [%d]",
				http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}
		/*Only allow GET method*/
		if r.Method != "GET" {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			log.Printf("[INFO] Server responded with: [%v] and status: [%d]",
				http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}
		/*Set the response headers*/
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		/*Call the chained service*/
		resp, err := http.Get(CHAIN_URL)
		if err != nil {
			/*Error header*/
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Hello, Go! No chained response"))
			log.Printf("[INFO] Server responded with: [%v] and status: [%d]",
				"Hello, Go! No chained response", http.StatusInternalServerError)
			return
		}
		/*Read the response body*/
		body, err := ioutil.ReadAll(resp.Body)
		/*Closing response body*/
		defer resp.Body.Close()
		if err != nil {
			/*Error handler*/
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Hello, Go! Could not read the chained response body"))
			log.Printf("[INFO] Server responded with: [%v] and status: [%d]",
				"Hello, Go! Could not read the chained response body", http.StatusInternalServerError)
			return
		}
		/*Successful*/
		w.WriteHeader(http.StatusOK)
		var msg []byte
		msg = append([]byte("Hello, Go! Chained reponse: "),body...)
		w.Write(msg)
		log.Printf("[INFO] Server responded with: [%v] and status: [%d]", msg, http.StatusOK)
		return
	})
}
/*Health check handler*/
func healthz () http.Handler {
	return http.HandlerFunc( func (w http.ResponseWriter, r *http.Request) {
		/*Only allow GET method*/
		if r.Method != "GET" {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}
		/*Only allow URL path: health*/
		if r.URL.Path != "/health" {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}
		/*Set the response headers*/
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		/*Return empty response*/
		w.WriteHeader(http.StatusNoContent)
		return
	})
}