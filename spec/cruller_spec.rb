require 'cruller'

TEST_DIR = File.join(File.dirname(__FILE__), "..", "test")
COFFEE_DIR = File.join(TEST_DIR, "coffeescripts")
JS_DIR = File.join(TEST_DIR, "javascripts")

APP_COFFEE = File.join(COFFEE_DIR, "app.coffee")
APP_JS = File.join(JS_DIR, "app.js")

EMPTY_JS = "(function() {\n\n}).call(this);\n"

# Set up our environment.
def clean
  FileUtils.rm_r(COFFEE_DIR) if File.directory?(COFFEE_DIR)
  FileUtils.rm_r(JS_DIR) if File.directory?(JS_DIR)
  FileUtils.mkdir_p(COFFEE_DIR)
  FileUtils.mkdir_p(JS_DIR)
  File.open(APP_COFFEE, "w") do |f|
    f.write ""
  end
end

def taint_cache(file=APP_JS)
  # Cheat by screwing with the cache and making sure Cruller returns that
  File.open(file, "w") do |f|
    f.write "cache file"
  end
end

describe Cruller, '#brew' do
  Cruller.configure({:source => "test/coffeescripts",
                     :destination => "test/javascripts"})

  it "returns false for a file that doesn't exist" do
    clean
    result = Cruller.brew("nonexistant")
    result.should == false
  end

  it "returns CoffeeScript for a file" do
    clean
    result = Cruller.brew("app")
    result.should == EMPTY_JS
  end

  it "should cache on clean compile" do
    clean
    Cruller.brew("app")
    File.file?(APP_JS).should == true
    File.open(APP_JS, "r").read.should == EMPTY_JS
  end

  it "should use the cache when Coffee isn't newer" do
    clean
    Cruller.brew("app")
    taint_cache
    Cruller.brew("app").should == "cache file"
  end

  it "should recompile when the Coffee is newer" do
    clean
    Cruller.brew("app")
    taint_cache
    sleep 1
    FileUtils.touch(APP_COFFEE)
    Cruller.brew("app").should == EMPTY_JS
    File.open(APP_JS, "r").read.should == EMPTY_JS
  end

  it "should never compile if :compile => never" do
    clean
    Cruller.configure({:source => "test/coffeescripts",
                       :destination => "test/javascripts",
                       :compile => "never"})
    Cruller.brew("app")
    File.file?(APP_JS).should == false
  end

  it "should always compile if :compile => always" do
    clean
    Cruller.configure({:source => "test/coffeescripts",
                       :destination => "test/javascripts",
                       :compile => "always"})
    taint_cache
    Cruller.brew("app").should == EMPTY_JS
    File.open(APP_JS, "r").read.should == EMPTY_JS
  end

  describe "when dealing with static JS" do

    it "should return it when always compiling" do
      clean
      taint_cache(File.join(JS_DIR, "jquery.js"))
      Cruller.configure({:source => "test/coffeescripts",
                         :destination => "test/javascripts",
                         :compile => "always"})
      Cruller.brew("jquery").should == "cache file"
    end

    it "should return it when auto compiling" do
      clean
      taint_cache(File.join(JS_DIR, "jquery.js"))
      Cruller.configure({:source => "test/coffeescripts",
                         :destination => "test/javascripts",
                         :compile => "auto"})
      Cruller.brew("jquery").should == "cache file"
    end

    it "should return it when never compiling" do
      clean
      taint_cache(File.join(JS_DIR, "jquery.js"))
      Cruller.configure({:source => "test/coffeescripts",
                         :destination => "test/javascripts",
                         :compile => "never"})
      Cruller.brew("jquery").should == "cache file"
    end
  end

end
