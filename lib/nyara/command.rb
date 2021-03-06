require "thor"
require "shellwords"

module Nyara
  class Command < Thor
    include Thor::Actions

    module FileNames
      def template_ext
        options[:template] == 'slim' ? 'slim' : 'erb'
      end

      def gitignore
        '.gitignore'
      end
    end
    include FileNames

    module ORM
      def orm
        # it can be nil when called as method
        options[:orm] || 'mongoid'
      end
    end
    include ORM

    map '-v' => :version

    def self.source_root
      __dir__
    end

    desc "version", "Show version"
    def version
      puts "Nyara #{Nyara::VERSION}"
    end

    desc "new APP_NAME", "Create a project"
    method_option :orm, aliases: %w'-o -O', type: :string, default: 'mongoid',
                  desc: 'Specify object relationship mapping (ORM)', enum: %w'mongoid activerecord none'
    method_option :template, aliases: %w'-t -T', type: :string, default: 'erubis',
                  desc: 'Specify template engine', enum: %w'erubis slim'
    def new name
      require 'fileutils'

      app_dir = File.expand_path File.join(Dir.pwd, name)
      @rel_dir = name
      @app_name = File.basename app_dir
      templte_dir = File.join(File.dirname(__FILE__), "templates")

      directory 'templates', name
      generate 'session.key'
      generate 'database.yml'
      puts '          \\ 👻  /'
    ensure
      @app_name = nil
      @rel_dir = nil
    end

    desc "generate THING", "(PROJECT) Generate things, THING can be:
    session.key            # config/session.key
    session_cipher.key     # config/session_cipher.key
    database.yml           # config/database.yml
    migration create_users # db/migrate/20130901231200_create_users.rb"
    method_option :orm, aliases: %w'-o -O', type: :string, default: 'mongoid',
                  desc: 'Specify ORM (for generating database.yml)', enum: %w'mongoid activerecord'
    method_option :version, aliases: %w'-v -V', type: :numeric,
                  desc: 'Specify VERSION (for generate migration)'
    def generate thing, migration=nil
      case thing
      when 'session.key'
        file = "config/session.key"
        file = File.join @rel_dir, file if @rel_dir
        create_file file do
          Session.generate_key
        end
      when 'session_cipher.key'
        file = 'config/session_cipher.key'
        file = File.join @rel_dir, file if @rel_dir
        create_file file do
          Session.generate_cipher_key
        end
      when 'database.yml'
        @app_name ||= File.dirname Dir.pwd
        file = 'config/database.yml'
        file = File.join @rel_dir, file if @rel_dir
        case orm
        when 'mongoid', 'activerecord'
          src = "#{__dir__}/optional_templates/#{orm}.yml.erb"
          create_file file do
            ERB.new(File.read src).result binding
          end
        end
      when 'migration'
        if migration.nil?
          abort 'Use: nyara g migration YOUR_MIGRATION_NAME'
        end
        version = options[:version] || Time.now.utc.strftime("%Y%m%d%H%M%S")
        create_file "db/migrate/#{version}_#{migration}.rb" do
          @name = migration.gsub(/_(.)/) { $1.upcase }.gsub(/^(.)/) { $1.upcase }
          src = "#{__dir__}/optional_templates/migration.rb.erb"
          ERB.new(File.read src).result binding
        end
        @name = nil
      end
    end

    desc "server", "(PROJECT) Start server"
    method_option :environment, aliases: %w'-e -E', default: 'development'
    method_option :port, aliases: %w'-p -P', type: :numeric
    method_option :daemon, aliases: %w'-d -D', type: :boolean,
                  desc: 'run server on the background'
    def server
      env = options[:environment].shellescape
      cmd = "NYARA_ENV=#{env} ruby config/boot.rb"

      if options[:port]
        cmd << " -p " << options[:port].to_s.shellescape
      end
      if options[:daemon]
        cmd << " -d"
      end
      exec cmd
    end

    desc "console", "(PROJECT) Start console"
    method_option :environment, aliases: %w'-e -E', default: 'development'
    method_option :shell, aliases: %w'-s -S', enum: %w'pry irb',
                  desc: "Tell me which shell you want to use"
    def console
      env = options[:environment].shellescape
      cmd = options[:shell]
      unless cmd
        if File.read('Gemfile') =~ /\bpry\b/
          cmd = 'pry'
        end
      end

      cmd ||= 'irb'
      if cmd != 'irb'
        cmd = "bundle exec pry"
      end
      exec "NYARA_SHELL=1 NYARA_ENV=#{env} #{cmd} -r./config/application.rb"
    end

  end
end
