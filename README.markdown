DESCRIPTION:
============

A simple, clean DSL for describing, writing, and parsing fixed-width text files.

FEATURES:
=========

* Easy to use DSL with trickle-down configuration
* Reusable, templated schemata
* Flexible Section Definitions:
  * Repeated or Singular
  * Ordered or Unordered
  * Required or Optional
* Supports custom data output mechanisms
* Supports multibyte characters

SPECIAL NOTE:
=============

An attempt to integrate and improve the various forks of `ryanwood/slither`.

SYNOPSIS:
=========

##OUTDATED AFTER THIS POINT

##Creating a definition (Quick 'n Dirty)

Hopefully this will cover 90% of use cases.

    # Create a FixedWidth::Defintion to describe a file format
    FixedWidth.define :simple do |d|
      # This is a template section that can be reused in other sections
      d.template :boundary do |t|
        t.column :record_type, 4
        t.column :company_id, 12
      end

      # Create a section named :header
      d.header(:align => :left) do |header|
        # The trap tells FixedWidth which lines should fall into this section
        header.trap { |line| line[0,4] == 'HEAD' }
        # Use the boundary template for the columns
        header.template :boundary
      end

      d.body do |body|
        body.trap { |line| line[0,4] =~ /[^(HEAD|FOOT)]/ }
        body.column :id, 10, :parser => :to_i
        body.column :first, 10, :align => :left, :group => :name
        body.column :last,  10, :align => :left, :group => :name
        body.spacer 3
        body.column :city, 20  , :group => :address
        body.column :state, 2  , :group => :address
        body.column :country, 3, :group => :address
      end

      d.footer do |footer|
        footer.trap { |line| line[0,4] == 'FOOT' }
        footer.template :boundary
        footer.column :record_count, 10, :parser => :to_i
      end
    end

This definition would output a parsed file something like this:

    {
        :body => [
          { :id => 12,
            :name => { :first => "Ryan", :last => "Wood" },
            :address => { :city => "Foo", :state => 'SC', :country => "USA" }
          },
          { :id => 13,
            :name => { :first => "Jo", :last => "Schmo" },
            :address => { :city => "Bar", :state => "CA", :country => "USA" }
          }
        ],
        :header => [{ :record_type => 'HEAD', :company_id => 'ABC'  }],
        :footer => [{ :record_type => 'FOOT', :company_id => 'ABC', :record_count => 2  }]
    }

##Sections
###Declaring a section

Sections can have any name, however duplicates are not allowed (a `DuplicateNameError` will be thrown). We use the standard `method_missing` trick. So if you see any unusual behavior, that's probably the first spot to look.

    FixedWidth.define :simple do |d|
        d.a_section_name do |s|
            ...
        end
        d.another_section_name do |s|
            ...
        end
    end

### Section options:

* `:singular` (default `false`) indicates that the section will only have a single record, and that it should not be returned nested in an array.

* `:optional` (default `false`) indicates that the section is optional. (An otherwise-specified section will raise a `RequiredSectionNotFoundError` if the trap block doesn't match the row after the last one of the previous section.)

##Columns
###Declaring a column

Columns can have any name, except for `:spacer` which is reserved. Also, duplicate column names within groupings are not allowed, and a column cannot share the same name as a group (a `DuplicateNameError` will be thrown). Again, basic `method_missing` trickery here, so be warned. You can declare columns either with the `method_missing` thing or by calling `Section#column`.

    FixedWidth.define :simple do |d|
        d.a_section_name do |s|
            s.a_column_name 12
            s.column :another_column_name, 14
        end
    end

###Column Options:

* `:align` can be set to `:left` or `:right`, to indicate which side the values should be/are justified to. By default, all columns are aligned `:right`.

* `:group` can be set to a `Symbol` indicating the name of the nested hash which the value should be parsed to when reading/the name of the nested hash the value should be extracted from when writing.

* `:parser` and `:formatter` options are symbols (to be proc-ified) or procs. By default, parsing and formatting assume that we're expecting/writing right-aligned strings, padded with spaces.

* `:nil_blank` set to true will cause whitespace-only fields to be parsed to nil, regardless of `:parser`.

* `:padding` can be set to a single character that will be used to pad formatted values, when writing fixed-width files.

* `:truncate` can be set to true to truncate any value that exceeds the `length` property of a column. If unset or set to `false`, a `FixedWidth::FormatError` exception will be thrown.

##Writing out fixed-width records

Then either feed it a nested struct with data values to create the file in the defined format:

    test_data = {
        :body => [
          { :id => 12,
            :name => { :first => "Ryan", :last => "Wood" },
            :address => { :city => "Foo", :state => 'SC', :country => "USA" }
          },
          { :id => 13,
            :name => { :first => "Jo", :last => "Schmo" },
            :address => { :city => "Bar", :state => "CA", :country => "USA" }
          }
        ],
        :header => [{ :record_type => 'HEAD', :company_id => 'ABC'  }],
        :footer => [{ :record_type => 'FOOT', :company_id => 'ABC', :record_count => 2  }]
    }

    # Generates the file as a string
    puts FixedWidth.generate(:simple, test_data)

    # Writes the file
    FixedWidth.write(file_instance, :simple, test_data)

Or parse files already in that format into a nested hash:

    parsed_data = FixedWidth.parse(file_instance, :test).inspect

INSTALL:
========

    sudo gem install fixed_width
