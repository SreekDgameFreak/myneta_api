require 'roda'
require 'json'
require './lib/neta_scraper'

# Main app class
class MyNeta < Roda
    # All possible years for MPs
    YEARS = %w(2004 2009 2014)

    plugin :json, serializer: proc { |o| JSON.pretty_generate(o) }
        
    route do |r|
        # Single initialization of the JSON object returned
        ret = {}

        # GET / request
        r.root do
            # Show endpoint examples
            {
                mps: {
                    endpoint: '/mps',
                    sample: '/mps[/year][/state or union_territory]',
                    examples: %W(/mps/#{YEARS.sample} /mps/2014/#{MP_STATES.sample})
                },
                mlas: {
                    endpoint: '/mlas',
                    sample: '/mlas[/state]',
                    examples: %W(/mlas /mlas/maharashtra /mlas/#{(MLA_STATES - %w(maharashtra)).sample})
                },
                states: MLA_STATES,
                union_territories: MP_STATES - MLA_STATES
            }
        end

        # /scrape branch
        r.on 'scrape' do
            # Get all states
            r.is do
                neta_scraper_all
            end

            # Get one state only
            r.get ':state' do |state|
                neta_scraper(state)
            end
        end

        # Route for getting MPs
        r.on 'mps' do
            r.is do
                ret[:count] = MP.count
                ret[:mps] = MP.order_by(:year, :state_or_ut).map(&:format)
                ret
            end

            r.on :year do |year|
                if YEARS.member?(year)
                    r.is do
                        ret[:count] = MP.filter(year: year).count
                        ret[:mps] = MP.filter(year: year).order_by(:state_or_ut, :constituency)
                                    .map { |mp| mp.format(%i(mp_id year)) }
                        ret
                    end
                    
                    r.get :state do |state|
                        if MP_STATES.member?(state)
                            state = format_state(state)
                            ret[:count] = MP.filter(year: year, state_or_ut: state).count
                            ret[:mps] = MP.filter(year: year, state_or_ut: state).order_by(:constituency)
                                        .map { |mp| mp.format(%i(mp_id year state_or_ut)) }
                        else
                            ret[:valid_states] = MP_STATES
                        end
                        ret
                    end
                else
                    ret[:valid_years] = YEARS
                    ret
                end
            end
        end

        # Route for getting MLAs
        r.on 'mlas' do
            r.is do
                ret[:count] = MLA.count
                ret[:mlas] = MLA.map(&:format)
                ret
            end

            r.get ':state' do |state|
                if MLA_STATES.member?(state)
                    formatted_state = format_state(state)
                    {
                        state: formatted_state,
                        count: MLA.filter(state: formatted_state).count,
                        # Retrieve and format the required MLAs
                        mlas: MLA.filter(state: formatted_state)
                          .map { |mla| mla.format(%i(mla_id state)) }
                    }
                else
                    {
                        error: 'That is not a valid state'
                    }
                end
            end
        end
    end
end
