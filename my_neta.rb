require 'roda'
require 'json'
require './neta_scraper'
require './models.rb'

class MyNeta < Roda

    plugin :json
    
    route do |r|
        # GET / request
        r.root do
            {
                'ok' => true
            }
        end

        r.on 'scrape' do
            
            # Get all states
            r.is do
                neta_scraper_all()
            end

            # Get one state only
            r.get 'one/:state' do |state|
                neta_scraper(state)
            end

            r.get 'check_db' do
                hello_db
            end

        end

        # /message branch
        r.on 'message' do

            # /message?data
            r.is do
                {
                    'ok' => false,
                    'message' => r['data']
                }
            end
        end
    end
end