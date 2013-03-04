#!/usr/bin/env ruby

#
# This script helps you make doxygen comments in Obj-C/C/C++ files in XCode
#
# Created by Fred McCann on 03/16/2010 - and Edwin.
# http://www.duckrowing.com
# Adapted for ThisService by Martin Pichlmair 03/29/2011
# Modified for Objectiv-c by Dake 07/22/2012
# Modified by wtlucky 11/21/2012
# httip://glade.tk
#

module Duckrowing
    
    # Convenience class to hold name and type information
    class Argument
        def initialize(type = nil, name = nil)
            self.type = type
            self.name = name
        end
        
        def name
            @name
        end
        
        def name=(name)
            if name != nil
                name.gsub!(/^&/,'')
                name.gsub!(/^\*/,'')
                name.gsub!(/\[.*$/,'')
                name.gsub!(/,$/,'')
                name.gsub!(/;$/,'')
                name.gsub!(/^\s*/,'')
                name.gsub!(/\s*$/,'')
            end
            if name == '...'
                @name = 'vararg_list'
                else
                @name = name
            end
        end
        
        def type
            @type
        end
        
        def type=(type)
            if type != nil
                type.gsub!(/&$/,'')
                type.gsub!(/\s*\*$/,'')
                type.gsub!(/^\s*/,'')
                type.gsub!(/\s*$/,'')
            end
            @type = type
        end
    end
    
    # Base implementation of commenter
    class BaseCommenter
        # Creates a new commenter object
        def initialize(indent, code)
            @indent = indent
            @code = code
            @arguments = []
            @returns = false
        end
        
        # Creates an opening comment
        def start_comment(description = 'Description')
            str = "/**\n"
            #str = "#{@indent}/**\n"
            str += "#{@indent} *\t<##{description}#>\n"
            str
        end
        
        def arguments_comment
            str = ''
            @arguments.each do |arg|
                if str == ''
                    str += "#{@indent} *\n"
                end
                str += "#{@indent} *\t@param \t#{arg.name} \t<##{arg.name} description#>\n"
            end
            str
        end
        
        def return_comment
            return '' if !@returns
            "#{@indent} *\n#{@indent} *\t@return\t<#return value description#>\n"
        end
        
        # Creates closing comment
        def end_comment()
            #"#{@indent} */\n"
            "#{@indent} */\n#{@indent}"
        end
        
        # Convenience method to detect multiline statements
        def is_multiline?
            @code =~ /\n/
        end
        
        # Adds inline comments to a comma delimited list
        def comment_list(list, base_indent='')
            commented_list = ""
            ids = list.split(/,/)
            ids.each do |id|
                id.gsub!(/\s*$/, '')
                id.gsub!(/^\s*/, '')
                list_id = "#{id}"
                list_id += ',' if id != ids.last
                id.gsub!(/\=.*$/, '')
                id.gsub!(/\[.*\]/, '')
                id.gsub!(/\s*$/, '')
                id.gsub!(/^\s*/, '')
                id.gsub!(/;/, '')
                id.gsub!(/\s*\:\s*\d+/,'')
                doc_id = id.split(/\s/).last
                doc_id.gsub!(/\*/, '')
                commented_list += "#{base_indent}" if id != ids.first
                commented_list += "#{@indent}\t#{list_id} /**< <##{doc_id} description#> */"
                commented_list += "\n" if id != ids.last
            end
            commented_list
        end
        
        # Parses a comma delimited list into an array of Argument objects
        def parse_c_style_argument_list(str)
            arguments = []
            str.split(/,/).each do |a|
                arg = Argument.new
                parts = a.split(/\s+/)
                arg.name = parts.last
                parts.delete_at(parts.size - 1)
                arg.type = parts.join(" ")
                @arguments << arg
            end
        end
        
        # Add Xcode selection markup to first editable field
        def select_first_field(str)
            # Add PBX selection to first field
            matches = str.scan(/\<\#.*\#\>/)
           if matches.size > 0
               first_field = matches[0].to_s
               # str.gsub!(/#{first_field}/, "%%%{PBXSelection}%%%#{first_field}%%%{PBXSelection}%%%")
               str.gsub!(/#{first_field}/, "#{first_field}")
           end
           
           str
        end
                               
   # Returns a comment above the code and the original section of commented code
   def document
       str = start_comment()
       str += arguments_comment()
       str += return_comment()
       str += end_comment()
       str += "#{@code}\n"
       #print "#{@code}"
       #matches = @code.scan(/\n/)
       #print matches.size
                               #if matches.size > 1
                               #str += "#{@code}"
                               #end
       select_first_field(str)
       end
   end
   
   class VariableCommenter < BaseCommenter
   # Adds a basic comment above individual variables and rewrites multiple
   # declaritions into an inline commented list
   def document
   if @code.gsub(/\n/, ' ') =~ /^([^\{]+\,)/
   commented_code = comment_list(@code)
   commented_code.sub!(/^\s*/,@indent);
   select_first_field("#{commented_code}")
   else
   super
   end
   end
   end
   
   class PropertyCommenter < BaseCommenter
   # Adds a basic comment above individual properties
   end
   
   class MacroCommenter < BaseCommenter
   # Parse out args for inclusion in comment
   def capture_args
   matches = @code.scan(/\(([^\(\)]*)\)/)
   parse_c_style_argument_list(matches[0].to_s)
   @returns = true
   end
   
   # Adds a basic comment above individual variables and rewrites multiple
   # declaritions into an inline commented list
   def document
   capture_args if @code =~ /\(/
                               super
                               end
                               end
                               
                               # Implementation of commenter to comment C style enums
                               class EnumCommenter < BaseCommenter
                               # Comments identifiers in the code block
                               def comment_code
                               block_match = /\{([^\{\}]*)\}/
                               matches = @code.scan(block_match)
                               return if matches.size != 1
                               
                               block = matches[0].to_s
                               @code.gsub!(block_match, "{\n#{comment_list(block)}\n#{@indent}}")
                               end
                               
                               # Comments the enum. This will write comments next to each name for a multiline
                               # statement. It will not for single line enumerations.
                               def document
                               comment_code if is_multiline?
                               super
                               end
                               end
                               
                               # Implementation of commenter to comment C style enums
                               class StructCommenter < BaseCommenter
                               # Comments semicolon delimited list of struct members
                               def comment_struct_list(list)
                               commented_list = ""
                               ids = list.gsub(/^\s*/,'').gsub(/\s*$/,'').split(/;/)
                               ids.each do |id|
                               id.gsub!(/\s*$/, '')
                               id.gsub!(/^\s*/, '')
                               list_id = "#{id};"
                               base_indent = "\t"
                               commented_list += "#{comment_list(list_id, base_indent)}\n"
                               end
                               commented_list
                               end
                               
                               # Comments identifiers in the code block
                               def comment_code
                               block_match = /\{([^\{\}]*)\}/
                               matches = @code.scan(block_match)
                               return if matches.size != 1
                               
                               block = matches[0].to_s
                               @code.gsub!(block_match, "{\n#{comment_struct_list(block)}#{@indent}}")
                               end
                               
                               # Adds inline comments for members and a comment for the entire struct
                               def document
                               comment_code
                               super
                               end
                               end
                               
                               class FunctionCommenter < BaseCommenter
                               # Parse out args for inclusion in comment
                               def capture_args
                               matches = @code.scan(/\(([^\(\)]*)\)/)
                               parse_c_style_argument_list(matches[0].to_s)
                               end
                               
                               # Decides whether or not to add a returns tag to comment
                               def capture_return
                               @returns = @code.split(/\(/).first !~ /void/ 
                                                      end
                                                      
                                                      # Adds a basic comment above individual variables and rewrites multiple
                                                      # declaritions into an inline commented list
                                                      def document
                                                      capture_args
                                                      capture_return
                                                      super
                                                      end        
                                                      end
                                                      
                                                      class MethodCommenter < BaseCommenter
                                                      TAILMATCH = /[\s*;.*]/
                                                      
                                                      # Find the return type
                                                      def capture_return_type
                                                      matches = @code.scan(/^\s*[+-]\s*\(([^\(\)]*)\)/)
                                                      return nil if matches.size != 1
                                                      type = matches[0].to_s.gsub(TAILMATCH, '')
                                                      
                                                      if type == 'void' || type == 'IBAction'
                                                      @returns = nil
                                                      else
                                                      @returns = type
                                                      end
                                                      end
                                                      
                                                      # Parse out params
                                                      def capture_parameters
                                                      params = []
                                                      matches = @code.scan(/\:\(([^\(]+)\)(\S+)/)
                                                                           matches.each do |m|
                                                                           next if m.size != 2
                                                                           arg = Argument.new
                                                                           arg.type = m[0].to_s.gsub(TAILMATCH, '')
                                                                           arg.name = m[1].to_s.gsub(TAILMATCH, '')
                                                                           @arguments << arg        
                                                                           end
                                                                           end
                                                                           
                                                                           # Adds a basic comment above individual variables and rewrites multiple
                                                                           # declaritions into an inline commented list
                                                                           def document
                                                                           capture_parameters
                                                                           capture_return_type
                                                                           super
                                                                           end        
                                                                           end
                                                                           
                                                                           class Documenter    
                                                                           def document(code)
                                                                           # 此句刷格式缩进了
                                                                           #code.gsub!(/\s*$/, '')
                                                                           indent = base_indentation(code)     
                                                                           
                                                                           klass = nil
                                                                           
                                                                           if is_objc_property?(code)
                                                                           klass = PropertyCommenter   
                                                                           elsif is_objc_method?(code) 
                                                                           klass = MethodCommenter            
                                                                           elsif is_function?(code)
                                                                           klass = FunctionCommenter
                                                                           elsif is_macro?(code)
                                                                           klass = MacroCommenter
                                                                           elsif is_struct?(code)
                                                                           klass = StructCommenter
                                                                           elsif is_union?(code)
                                                                           klass = StructCommenter
                                                                           elsif is_enum?(code)
                                                                           klass = EnumCommenter
                                                                           else
                                                                           klass = VariableCommenter
                                                                           end
                                                                           
                                                                           #puts "USE --> #{klass}"
                                                                           commenter = klass.new(indent, code)
                                                                           commenter.document
                                                                           end
                                                                           
                                                                           private
                                                                           def is_objc_method?(code)
                                                                           code =~ /^\s*[+-]/      
                                                                           end
                                                                           
                                                                           def is_objc_property?(code)
                                                                           code =~ /^\s*\@property/      
                                                                           end
                                                                           
                                                                           def is_function?(code)
                                                                           !is_macro?(code) && !is_objc_method?(code) && code =~ /\(/
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    def is_macro?(code)
                                                                                                                                    code =~ /^\s*\#define/      
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    def is_enum?(code)
                                                                                                                                    code.gsub(/\n/, ' ') =~ /^\s*(\w+\s)?enum.*\{.*\}/      
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    def is_struct?(code)
                                                                                                                                    code.gsub(/\n/, ' ') =~ /^\s*(\w+\s)?struct.*\{.*\}/      
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    def is_union?(code)
                                                                                                                                    code.gsub(/\n/, ' ') =~ /^\s*(\w+\s)?union.*\{.*\}/      
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    def base_indentation(code)
                                                                                                                                    matches = code.scan(/^(\s*)/)
                                                                                                                                    return '' if matches.size == 0
                                                                                                                                    matches[0].to_s
                                                                                                                                    end
                                                                                                                                    end
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    
                                                                                                                                    # Unicode considerations:
                                                                                                                                    #  Set $KCODE to 'u'. This makes STDIN and STDOUT both act as containing UTF-8.
                                                                                                                                    $KCODE = 'u'
                                                                                                                                    
                                                                                                                                    #  Since any Ruby version before 1.9 doesn't much care for Unicode,
                                                                                                                                    #  patch in a new String#utf8_length method that returns the correct length
                                                                                                                                    #  for UTF-8 strings.
                                                                                                                                    UNICODE_COMPETENT = ((RUBY_VERSION)[0..2].to_f > 1.8)
                                                                                                                                    
                                                                                                                                    unless UNICODE_COMPETENT # lower than 1.9
                                                                                                                                    class String
                                                                                                                                    def utf8_length
                                                                                                                                    i = 0
                                                                                                                                    i = self.scan(/(.)/).length
                                                                                                                                    i
                                                                                                                                    end
                                                                                                                                    end
                                                                                                                                    else # 1.9 and above
                                                                                                                                    class String
                                                                                                                                    alias_method :utf8_length, :length
                                                                                                                                    end
                                                                                                                                    end
                                                                                                                                    
                                                                                                                                    input = STDIN.read
                                                                                                                                    # input now contains the contents of STDIN.
                                                                                                                                    # Write your script here. 
                                                                                                                                    # Be sure to print anything you want the service to output.
                                                                                                                                    documenter = Duckrowing::Documenter.new
                                                                                                                                    replacement = documenter.document(input)
                                                                                                                                    puts replacement
                                                                                                                                    #print replacement
                                                                                                                                    #print input
