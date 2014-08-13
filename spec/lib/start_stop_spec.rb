describe OptimusPrime, "Starting and Stopping the server" do
  it "starts the server" do
    OptimusPrime.restart_server
    expect( `ls ./tmp/pids` ).to include("optimus_prime.pid")
  end

  it "stops the server" do
    OptimusPrime.start_server
    OptimusPrime.stop_server
    expect( `ls ./tmp/pids` ).to_not include("optimus_prime.pid")
    OptimusPrime.start_server
  end

  it "informs me if the server is already running" do
    OptimusPrime.start_server
    expect( OptimusPrime.start_server ).to include("Optimus is already priming :)")
  end

end
