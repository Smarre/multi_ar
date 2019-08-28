
Given("I run {string}") do |command|
  puts `#{command}`
  expect($?.exitstatus).to eq(0)
end

When(/^I run "([^"]*)" for that project$/) do |command|
  Dir.chdir "/tmp" do
    Dir.chdir @project_name do
      #puts "Running #{command}..."
      puts `#{command}`
      expect($?.exitstatus).to eq(0)
    end
  end
end
