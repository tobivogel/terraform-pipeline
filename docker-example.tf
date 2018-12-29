provider "docker" {
  host = "tcp://localhost:2375"
}

data "docker_registry_image" "gocd-server" {
  name = "gocd/gocd-server:v18.12.0"
}

resource "docker_image" "gocd-server" {
  name = "${data.docker_registry_image.gocd-server.name}"
}

data "docker_registry_image" "gocd-agent" {
  name = "gocd/gocd-agent-alpine-3.8:v18.12.0"
}

resource "docker_image" "gocd-agent" {
  name = "${data.docker_registry_image.gocd-agent.name}"
}

resource "docker_container" "gocd-agent" {
  name = "gocd-agent"
  image = "${docker_image.gocd-agent.latest}"

  network_mode = "bridge"
  networks = ["gocd-network"]
  hostname = "go-agent-1"
  env = ["GO_SERVER_URL=https://gocd-server:8154/go","AGENT_AUTO_REGISTER_KEY=terraform-gocd-test"]
}

resource "docker_container" "gocd-server" {
  name = "gocd-server"
  image = "${docker_image.gocd-server.latest}"
  upload {
    content = "${file("cruise-config.xml")}"
#    file = "/godata/config/cruise-config.xml"
    file = "/etc/go/cruise-config.xml"
  }
  
  network_mode = "bridge"
  networks = ["gocd-network"]

  ports {
    internal = 8153
    external = 8153
  }
  ports {
    internal = 8154
    external = 8154
  }
}

resource "docker_network" "gocd-network" {
  name = "gocd-network"
}

