OWNER=novacloud
IMAGE_NAME=graphql-orm-changelog
QNAME=$(OWNER)/$(IMAGE_NAME)

GIT_TAG=$(QNAME):$(TRAVIS_COMMIT)
BUILD_TAG=$(QNAME):$(TRAVIS_BUILD_NUMBER).$(TRAVIS_COMMIT)
TAG=$(QNAME):`echo $(TRAVIS_BRANCH) | sed 's/master/latest/;s/develop/unstable/' | sed 's/\//-/'`


lint:
	docker run -it --rm -v "$(PWD)/Dockerfile:/Dockerfile:ro" redcoolbeans/dockerlint

build:
	docker build -t $(GIT_TAG) .
	
tag:
	docker tag $(GIT_TAG) $(BUILD_TAG)
	docker tag $(GIT_TAG) $(TAG)
	
login:
	@docker login -u "$(DOCKER_USER)" -p "$(DOCKER_PASS)"
push: login
	# docker push $(GIT_TAG)
	# docker push $(BUILD_TAG)
	docker push $(TAG)

generate:
	GO111MODULE=on go run github.com/novacloudcz/graphql-orm

reinit:
	GO111MODULE=on go run github.com/novacloudcz/graphql-orm init

migrate:
	TABLE_NAME_PREFIX=test DATABASE_URL=sqlite3://test.db PORT=8080 go run *.go migrate

run:
	DEBUG=true TABLE_NAME_PREFIX=test DATABASE_URL=sqlite3://test.db CLOUDEVENTS_PORT=8081 PORT=8080 go run *.go start --cors

voyager:
	docker run --rm -v `pwd`/gen/schema.graphql:/app/schema.graphql -p 8080:80 graphql/voyager

build-lambda-function:
	GO111MODULE=on GOOS=linux go build -o main lambda/main.go && zip lambda.zip main && rm main

test:
	GO111MODULE=on go build -o app *.go && DATABASE_URL=sqlite3://test.db ./app migrate && (DATABASE_URL=sqlite3://test.db CLOUDEVENTS_PORT=8081 PORT=8080 ./app start& export app_pid=$$! && make test-godog || test_result=$$? && kill $$app_pid && exit $$test_result)
// TODO: add detection of host ip (eg. host.docker.internal) for other OS
test-godog:
	docker run --rm --network="host" -v "${PWD}/features:/godog/features" -e GRAPHQL_URL=http://$$(if [[ $${OSTYPE} == darwin* ]]; then echo host.docker.internal;else echo localhost;fi):8080/graphql jakubknejzlik/godog-graphql
