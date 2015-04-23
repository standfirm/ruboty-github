module Ruboty
  module Github
    module Actions
      class Deploy < Base
        def call
          return require_access_token unless has_access_token?

          c = new_master
          create_branch("heads/#{name}_master", c.sha)
          update_branch("heads/deployment/#{name}", 'master')
          pr = pull_request("deployment/#{name}",
                            "#{name}_master",
                            "#{Time.now.strftime('%Y-%m-%d')} Deploy to #{name} by #{message.from_name}",
                            ENV['GITHUB_PR_DESCRIPTION'].to_s.gsub('\n',"\n") || '')
          message.reply("Created #{pr.html_url}")
        rescue Octokit::Unauthorized
          message.reply("Failed in authentication (401)")
        rescue Octokit::NotFound
          message.reply("Could not find that repository")
        rescue => exception
          message.reply("Failed by #{exception.class} #{exception}\n#{exception.backtrace}")
        end

        private

        def new_master
          if branch
            client.ref(repository, branch).object
          else
            create_empty_commit('master', 'Open PR')
          end
        end

        def pull_request(base, head, title, description)
          client.create_pull_request(repository, base, head, title, description)
        end

        def create_branch(name, sha1)
          client.create_ref(repository, name, sha1)
        end

        def update_branch(name, branch)
          client.update_ref(repository, name, sha1(branch), true)
        end

        def create_empty_commit(branch, message)
          current = client.branch(repository, branch)
          client.create_commit(repository, message,
                               current.commit.commit.tree.sha,
                               current.commit.sha)
        end

        def sha1(branch)
          client.branch(repository, branch).commit.sha
        end

        def branch
          message[:branch]
        end

        # e.g. sandbox
        def name
          message[:name]
        end

        # e.g. alice/foo:test
        def from
          message[:from]
        end

        # e.g. alice
        def from_user
          from.split("/").first
        end

        # e.g. test
        def from_branch
          from.split(":").last
        end

        # e.g. bob/foo
        def repository
          message[:repo]
        end
      end
    end
  end
end