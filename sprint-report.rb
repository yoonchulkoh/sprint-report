require 'net/http'
require 'uri'
require 'octokit'
require 'json'
require 'dotenv'

require 'pp'

Dotenv.load

WORKSPACE_ID = ENV['WORKSPACE_ID']
REPO_ID = ENV['REPO_ID']
ZENHUB_ACCESS_TOKEN = ENV['ZENHUB_ACCESS_TOKEN']
PERSONAL_ACCESS_TOKEN = ENV['PERSONAL_ACCESS_TOKEN']
REPOSITORY_NAME = ENV['REPOSITORY_NAME']
LABEL_NAME = ENV['LABEL_NAME']

def main
  json = get_pipelines

  pipelines = ['Sprint Backlog', 'In Progress', 'Review/QA', 'Done']
  json['pipelines']
    .select { |p| pipelines.include?(p['name']) }
    .each do |p|
    puts "### #{p['name']}"
    p['issues'].each do |issue|
      issue_obj = get_issue issue['issue_number']
      puts "##{issue_obj.number} #{issue_obj.title}" if issue_obj.labels.map(&:name).include?(LABEL_NAME)
    end
    puts ''
  end

  #   pp json
end

def get_pipelines
  uri = URI.parse("https://api.zenhub.com/p2/workspaces/#{WORKSPACE_ID}/repositories/#{REPO_ID}/board")
  request = Net::HTTP::Get.new(uri)
  request.content_type = 'application/json'
  request['X-Authentication-Token'] = ZENHUB_ACCESS_TOKEN

  req_options = {
    use_ssl: uri.scheme == 'https'
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  JSON.parse(response.body)
end

def get_issue(issue_number)
  client = Octokit::Client.new(access_token: PERSONAL_ACCESS_TOKEN)

  repo = client.repo REPOSITORY_NAME
  rel = repo.rels[:issues]
  rel.get(uri: { number: issue_number }).data
end

main
