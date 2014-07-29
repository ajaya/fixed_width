# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe FixedWidth::Section do
  before(:each) do
    @section = FixedWidth::Section.new(:body)
  end

  it "should have no columns after creation" do
    @section.columns.should be_empty
  end

  describe "when adding columns" do
    it "should build an ordered column list" do
      @section.should have(0).columns

      col1 = @section.column :id, 10
      col2 = @section.column :name, 30
      col3 = @section.column :state, 2

      @section.should have(3).columns
      @section.columns[0].should be(col1)
      @section.columns[1].should be(col2)
      @section.columns[2].should be(col3)
    end

    it "should create spacer columns" do
      @section.should have(0).columns
      @section.spacer(5)
      @section.should have(1).columns
    end

    it "can should override the alignment of the definition" do
      section = FixedWidth::Section.new('name', :align => :left)
      section.options[:align].should == :left
    end

    it "should use a missing method to create a column" do
      @section.should have(0).columns
      @section.first_name 5
      @section.should have(1).columns
    end

    it "should prevent duplicate column names without any groupings" do
      @section.column :id, 10
      lambda { @section.column(:id, 30) }.should raise_error(FixedWidth::DuplicateNameError, /column named 'id'/)
    end

    it "should prevent column names that already exist as groups" do
      @section.column :foo, 11, :group => :id
      lambda { @section.column(:id, 30) }.should raise_error(FixedWidth::DuplicateNameError, /group named 'id'/)
    end

    it "should prevent group names that already exist as columns" do
      @section.column :foo, 11
      lambda { @section.column(:id, 30, :group => :foo) }.should raise_error(FixedWidth::DuplicateNameError, /column named 'foo'/)
    end

    it "should prevent duplicate column names within groups" do
      @section.column :id, 10, :group => :foo
      lambda { @section.column(:id, 30, :group => :foo) }.should raise_error(FixedWidth::DuplicateNameError, /column named 'id' in the ':foo' group/)
    end

    it "should allow duplicate column names in different groups" do
      @section.column :id, 10, :group => :foo
      lambda { @section.column(:id, 30, :group => :bar) }.should_not raise_error(FixedWidth::DuplicateNameError)
    end

    it "should allow duplicate column names that are reserved (i.e. spacer)" do
      @section.spacer 10
      lambda { @section.spacer 10 }.should_not raise_error(FixedWidth::DuplicateNameError)
    end
  end

  it "should accept and store the trap as a block" do
    @section.trap { |v| v == 4 }
    trap = @section.instance_variable_get(:@trap)
    trap.should be_a(Proc)
    trap.call(4).should == true
  end

  describe "when adding a template" do
    before(:each) do
      @template = mock('templated section', :columns => [1,2,3], :options => {})
      @definition = mock("definition", :templates => { :test => @template } )
      @section.definition = @definition
    end

    it "should ensure the template exists" do
      @definition.stub! :templates => {}
      lambda { @section.template(:none) }.should raise_error(ArgumentError)
    end

    it "should add the template columns to the current column list" do
      @section.template :test
      @section.should have(3).columns
    end

    it "should merge the template option" do
       @section = FixedWidth::Section.new(:body, :align => :left)
       @section.definition = @definition
       @template.stub! :options => {:align => :right}
       @section.template :test
       @section.options.should == {:align => :left}
    end
  end

  describe "when formatting a row" do
    before(:each) do
      @data = { :id => 3, :name => "Ryan" }
    end

    it "should default to string data aligned right" do
      @section.column(:id, 5)
      @section.column(:name, 10)
      @section.format( @data ).should == "    3      Ryan"
    end

    it "should left align if asked" do
      @section.column(:id, 5)
      @section.column(:name, 10, :align => :left)
      @section.format(@data).should == "    3Ryan      "
    end

    it "should read from groups" do
      @data = { :id => 3, :foo => { :name => "Ryan" } }
      @section.column(:id, 5)
      @section.column(:name, 10, :align => :left, :group => :foo)
      @section.format(@data).should == "    3Ryan      "
    end
  end

  describe "when parsing a file" do
    before(:each) do
      @line = '   45      Ryan      WoódSC '
      @section = FixedWidth::Section.new(:body)
      @column_content = { :id => 5, :first => 10, :last => 10, :state => 2 }
    end

    it "should return a key for key column" do
      @column_content.each { |k,v| @section.column(k, v) }
      parsed = @section.parse(@line)
      @column_content.each_key { |name| parsed.should have_key(name) }
    end

    it "should not return a key for reserved names" do
      @column_content.each { |k,v| @section.column(k, v) }
      @section.spacer 5
      @section.should have(5).columns
      parsed = @section.parse(@line)
      parsed.should have(4).keys
    end

    it "should break columns into groups" do
      @section.column(:id, 5)
      @section.column(:first, 10, :group => :name)
      @section.column(:last, 10, :group => :name)
      @section.column(:state, 2, :group => :address)
      @section.spacer 5
      @section.should have(5).columns
      parsed = @section.parse(@line)
      parsed.should have(3).keys
      parsed[:id].should == '45'
      parsed[:name][:first].should == 'Ryan'
      parsed[:name][:last].should == 'Woód'
      parsed[:address][:state].should == 'SC'
    end

    it "should not die if a field is not in range" do
      @section.column(:a, 5)
      @section.column(:b, 5)
      @section.column(:c, 5)
      line = '   45'
      parsed = @section.parse(line)
      parsed[:a].should == '45'
      parsed[:b].should == ''
      parsed[:c].should == ''
    end
  end

  it "should try to match a line using the trap" do
    @section.trap do |line|
      line == 'hello'
    end
    @section.match('hello').should be_true
    @section.match('goodbye').should be_false
  end
end
