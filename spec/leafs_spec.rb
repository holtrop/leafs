require "fileutils"
require "open3"

RUN_DIR = "spec/run"

describe "leafs" do
  before(:all) do
    $owd = Dir.pwd
  end

  before(:each) do
    Dir.chdir $owd
    FileUtils.rm_rf(RUN_DIR)
    FileUtils.mkdir_p(RUN_DIR)
    Dir.chdir RUN_DIR
  end

  after(:each) do
    Dir.chdir $owd
    FileUtils.rm_rf(RUN_DIR)
  end

  def run(command)
    stdout, stderr, status = Open3.capture3(*command)
    unless status == 0
      raise "#{stderr}#{status} for command #{command}"
    end
    [stdout, stderr, status]
  end

  def write_test(contents)
    File.binwrite("test.d", <<EOF)
import leafs;
import std.stdio;

int main()
{
    return 0;
}

unittest
{
#{contents}
}
EOF
  end

  it "generates a module to access file contents" do
    write_test(<<EOF)
    auto leafs_file = Leafs.get("leafs");
    assert(leafs_file !is null);
    writeln("Length = ", leafs_file.length);
    ubyte checksum;
    foreach (b; leafs_file)
    {
        checksum += b;
    }
    writeln("Checksum = ", checksum);
    assert(Leafs.get("foo") is null);
EOF
    FileUtils.cp("#{$owd}/leafs", ".")
    run(%W[#{$owd}/leafs -o leafs.d leafs])
    run(%W[gdc -funittest -o test test.d leafs.d])
    stdout, stderr, _ = run(%W[./test])
    leafs_contents = File.binread("#{$owd}/leafs")
    checksum = leafs_contents.bytes.reduce(:+) & 0xFF
    raise unless stdout =~ /Length = (\d+).*Checksum = (\d+)/m
    test_length, test_checksum = $1.to_i, $2.to_i
    expect(test_length).to eq leafs_contents.length
    expect(test_checksum).to eq checksum
  end

  it "recurses directories" do
    write_test(<<EOF)
    auto file = cast(char[])Leafs.get("f.txt");
    assert(file == "abc");
    file = cast(char[])Leafs.get("d1/f1.txt");
    assert(file == "1");
    file = cast(char[])Leafs.get("d1/d2/f2.txt");
    assert(file == "12");
    file = cast(char[])Leafs.get("d1/d2/d3/f3.txt");
    assert(file == "123");
EOF
    FileUtils.mkdir_p("d1/d2/d3")
    File.binwrite("f.txt", "abc")
    File.binwrite("d1/f1.txt", "1")
    File.binwrite("d1/d2/f2.txt", "12")
    File.binwrite("d1/d2/d3/f3.txt", "123")
    run(%W[#{$owd}/leafs -o leafs.d d1 f.txt])
    run(%W[gdc -funittest -o test test.d leafs.d])
    run(%W[./test])
  end

  it "allows stripping prefixes from asset paths" do
    write_test(<<EOF)
    auto file = cast(char[])Leafs.get("f.txt");
    assert(file == "abc");
    file = cast(char[])Leafs.get("f1.txt");
    assert(file == "1");
    file = cast(char[])Leafs.get("f2.txt");
    assert(file == "12");
EOF
    FileUtils.mkdir_p("d1")
    FileUtils.mkdir_p("assets")
    File.binwrite("f.txt", "abc")
    File.binwrite("d1/f1.txt", "1")
    File.binwrite("assets/f2.txt", "12")
    run(%W[#{$owd}/leafs -o leafs.d -s d1 --strip assets/ d1 assets f.txt])
    run(%W[gdc -funittest -o test test.d leafs.d])
    run(%W[./test])
  end
end
