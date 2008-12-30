module Cms
  class << self
    __root__ = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    define_method(:root) { __root__ }
    def load_rake_tasks
      load "#{Cms.root}/lib/tasks/cms.rake"
    end
    # This is called after the environment is ready
    def init
      
      #Laod all the CMS Routes
      ActionController::Routing::RouteSet::Mapper.send :include, Cms::Routes
      
      ActiveSupport::Dependencies.load_paths += %W( #{RAILS_ROOT}/app/portlets )
      
      #Write out the page templates to the file system
      if ActiveRecord::Base.connection.tables.include?("page_templates")
        tmp_view_path = "#{Rails.root}/tmp/views"
        Rails.logger.info("~~ Writing page templates to #{tmp_view_path}")
        ActionController::Base.append_view_path tmp_view_path
        PageTemplate.all.each{|pt| pt.create_layout_file }
      end      
      ActionView::Base.default_form_builder = Cms::FormBuilder
    end
    
    # This is used by CMS modules to register with the CMS generator
    # which files should be copied over to the app when the CMS generator is run.
    # src_root is the absolute path to the root of the files,
    # then each argument after that is a Dir.glob pattern string.
    def add_generator_paths(src_root, *files)
      generator_paths << [src_root, files]
    end
    
    def generator_paths
      @generator_paths ||= []
    end   
    
    def add_to_rails_paths(path)
      ActiveSupport::Dependencies.load_paths += [
        File.join(path, "app", "controllers"),
        File.join(path, "app", "helpers"),
        File.join(path, "app", "models"),
        File.join(path, "app", "portlets")
      ]
      Rails.configuration.controller_paths << File.join(path, "app", "controllers")
      ActionController::Base.append_view_path File.join(path, "app", "views")      
    end
    
    def markdown?
      Object.const_defined?("Markdown")
    end
     
  end
  module Errors
    class AccessDenied < StandardError
      def initialize
        super("Access Denied")
      end
    end
  end
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
	:year_month_day => '%Y/%m/%d',
	:date => '%m/%d/%Y'	
)

Cms.add_generator_paths(Cms.root, 
  "public/javascripts/jquery*", 
  "public/javascripts/cms/**/*", 
  "public/fckeditor/**/*", 
  "public/site/**/*",   
  "public/stylesheets/cms/**/*", 
  "public/images/cms/**/*", 
  "db/migrate/[0-9]*_*.rb")