require 'spec_helper'

describe 'commands' do
  before(:all) do
    set :backend, :docker
    set :docker_image, "registrator-aws:latest"
    set :docker_container_create_options, {
        "Entrypoint" => "/bin/sh"
    }
  end

  after(:all, &:reset_docker_backend)

  it "includes the registrator command" do
    expect(command('/opt/registrator/bin/registrator --version').stdout)
        .to(match(/4322fe00304d6de661865721b073dc5c7e750bd2/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
