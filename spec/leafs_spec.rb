require "fileutils"
require "open3"

RUN_DIR = "spec/run"

describe "leafs" do
  before(:each) do
    FileUtils.rm_rf(RUN_DIR)
    FileUtils.mkdir_p(RUN_DIR)
  end

#  after(:each) do
#    FileUtils.rm_rf(RUN_DIR)
#  end

  def run(command)
    stdout, stderr, status = Open3.capture3(*command)
    unless status == 0
      raise "#{stderr}#{status} for command #{command}"
    end
    [stdout, stderr, status]
  end

  def write_test(contents)
    File.binwrite("#{RUN_DIR}/test.d", <<EOF)
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
    run(%W[./leafs -o #{RUN_DIR}/leafs.d leafs])
    run(%W[gdc -funittest -o #{RUN_DIR}/test #{RUN_DIR}/test.d #{RUN_DIR}/leafs.d])
    stdout, stderr, _ = run(%W[#{RUN_DIR}/test])
    leafs_contents = File.binread("leafs")
    checksum = leafs_contents.bytes.reduce(:+) & 0xFF
    raise unless stdout =~ /Length = (\d+).*Checksum = (\d+)/m
    test_length, test_checksum = $1.to_i, $2.to_i
    expect(test_length).to eq leafs_contents.length
    expect(test_checksum).to eq checksum
  end
end
