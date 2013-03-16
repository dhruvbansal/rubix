require 'spec_helper'

describe Rubix::Sender do

  let(:measurement) { { key: 'question.life.universe.everything', value: 42 } }

  context "has sensible defaults" do
    its(:host)   { should == 'localhost' }
    its(:server) { should == 'localhost' }
    its(:port)   { should == 10051       }
  end

  it "adds its default host to measurements" do
    subject.format_measurement(measurement)[:host].should == subject.host
  end

  it "opens and closes a socket on each write" do
    socket = double("TCPSocket instance")
    TCPSocket.should_receive(:new).with(subject.host, subject.port).and_return(socket)
    socket.should_receive(:write)
    socket.should_receive(:recv)
    socket.should_receive(:close)
    subject.transmit(measurement)
  end

end
  
