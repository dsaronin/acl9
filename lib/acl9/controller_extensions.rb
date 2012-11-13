require File.join(File.dirname(__FILE__), 'controller_extensions', 'generators')

module Acl9
  module ControllerExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def access_control(*args, &block)

puts "###### ACL9 ##### head of method  ######"

        opts = args.extract_options!

        case args.size
        when 0 then true
        when 1
          meth = args.first

          if meth.is_a? Symbol
            opts[:as_method] = meth
          else
            raise ArgumentError, "access_control argument must be a :symbol!"
          end
        else
          raise ArgumentError, "Invalid arguments for access_control"
        end

        subject_method = opts[:subject_method] || Acl9::config[:default_subject_method]

puts "###### ACL9 ##### subject_method=#{subject_method.to_s} ######"

        raise ArgumentError, "Block must be supplied to access_control" unless block

        filter = opts[:filter]
        filter = true if filter.nil?

        case helper = opts[:helper]
        when true
          raise ArgumentError, "you should specify :helper => :method_name" if !opts[:as_method]
        when nil then nil
        else
          if opts[:as_method]
            raise ArgumentError, "you can't specify both method name and helper name" 
          else
            opts[:as_method] = helper
            filter = false
          end
        end

        method = opts[:as_method]

puts "###### ACL9 ##### method=#{method.to_s} ######"

        query_method_available = true
        generator = case
                    when method && filter
                      Acl9::Dsl::Generators::FilterMethod.new(subject_method, method)
                    when method && !filter
                      query_method_available = false
                      Acl9::Dsl::Generators::BooleanMethod.new(subject_method, method)
                    else
                      Acl9::Dsl::Generators::FilterLambda.new(subject_method)
                    end

puts "###### ACL9 ##### generator=#{generator.class.name} ######"


        generator.acl_block!(&block)   # shouldn't be commented out

return true
        generator.install_on(self, opts)

puts "###### ACL9 ##### install_on ######"

        if query_method_available && (query_method = opts.delete(:query_method))
          case query_method
          when true
            if method
              query_method = "#{method}?"
            else
              raise ArgumentError, "You must specify :query_method as Symbol"
            end
          when Symbol, String
            # okay here
          else
            raise ArgumentError, "Invalid value for :query_method"
          end

          second_generator = Acl9::Dsl::Generators::BooleanMethod.new(subject_method, query_method)

puts "###### ACL9 ##### second_generator=#{second_generator.inspect} ######"

          second_generator.acl_block!(&block)
          second_generator.install_on(self, opts)
        end
      end
    end
  end
end
