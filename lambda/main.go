package main

import (
	"github.com/akrylysov/algnhsa"
	"github.com/novacloudcz/graphql-orm-changelog/gen"
	"github.com/novacloudcz/graphql-orm-changelog/src"
	"github.com/novacloudcz/graphql-orm/events"
)

func main() {
	db := gen.NewDBFromEnvVars()

	eventController, err := events.NewEventController()
	if err != nil {
		panic(err)
	}

	handler := gen.GetHTTPServeMux(src.New(db, &eventController), db)
	algnhsa.ListenAndServe(handler, nil)
}
