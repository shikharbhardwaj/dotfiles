VERSION:=0.4

build-docker:
	docker build -t desk:latest ../../ -f ./Dockerfile

run-docker: build-docker
	docker run -it --rm --user coder desk:latest

push-docker: build-docker
	docker tag desk:latest bluefog/desk:$(VERSION)
	docker push bluefog/desk:$(VERSION)
