require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
      'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
      'AWS_S3_BUCKET_REGION' => s3_bucket_region,
      'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'registrator-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
          'Binds' => ["/var/run/docker.sock:/tmp/docker.sock"],
          'NetworkMode' => 'docker_registrator_aws_test_default'
      }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'runs registrator' do
      expect(process('/opt/registrator/bin/registrator')).to(be_running)
    end

    it 'does not cleanup' do
      expect(process('/opt/registrator/bin/registrator').args)
          .not_to(match(/-cleanup/))
    end

    it 'always deregisters' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-deregister always/))
    end

    it 'never resyncs' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-resync 0/))
    end

    it 'does not set a TTL' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-ttl 0/))
    end

    it 'does not set a TTL refresh frequency' do
      expect(process('/opt/registrator/bin/registrator').args)
          .not_to(match(/-ttl-refresh/))
    end
  end

  describe 'with cleanup enabled' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_CLEANUP_ENABLED" => "yes"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'cleans up' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-cleanup/))
    end
  end

  describe 'with cleanup disabled' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_CLEANUP_ENABLED" => "no"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'cleans up' do
      expect(process('/opt/registrator/bin/registrator').args)
          .not_to(match(/-cleanup/))
    end
  end

  describe 'with deregister on-success' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_DEREGISTER_MODE" => "on-success"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'uses on-success as deregister mode' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-deregister on-success/))
    end
  end

  describe 'with deregister always' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_DEREGISTER_MODE" => "always"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'uses on-success as deregister mode' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-deregister always/))
    end
  end

  describe 'with resync configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_RESYNC_SECONDS" => "5"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided resync seconds' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-resync 5/))
    end
  end

  describe 'with ttl configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              "REGISTRATOR_REGISTRY_URI" => "consul://consul:8500",
              "REGISTRATOR_TTL_SECONDS" => "30",
              "REGISTRATOR_TTL_REFRESH_SECONDS" => "10"
          })

      execute_docker_entrypoint(
          started_indicator: "Syncing")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided ttl seconds' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-ttl 30/))
    end

    it 'uses the provided ttl refresh seconds' do
      expect(process('/opt/registrator/bin/registrator').args)
          .to(match(/-ttl-refresh 10/))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
        .merge(content: (opts[:env] || {})
            .to_a
            .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
            .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    args = (opts[:arguments] || []).join(' ')

    execute_command(
        "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 15) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end
