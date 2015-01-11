require 'mechanize'
require 'scraperwiki'

@agent = Mechanize.new
url = 'http://datrack.canterbury.nsw.gov.au/cgi/datrack.pl?status=On Notification&search=search'

def save_applications(application_list)
  application_list.search('.datrack_resultrow_odd,.datrack_resultrow_even').each do |row|
    info_url = row.at(:a).attr(:href)
    day, month, year = row.at('.datrack_lodgeddate_cell').inner_text.split('/').map { |n| n.to_i }
    address = row.at('.datrack_houseno_cell').inner_text + ' ' +
              row.at('.datrack_street_cell').inner_text + ', ' +
              row.at('.datrack_town_cell').inner_text + ' NSW'

    detail_page = @agent.get info_url

    application = {
      council_reference: row.at(:a).inner_text,
      address: address,
      description: detail_page.at('.wh_preview_master').search(:td)[1].inner_text,
      info_url: info_url,
      comment_url: 'mailto:council@canterbury.nsw.gov.au',
      date_scraped: Date.today,
      date_received: Date.new(year, month, day)
    }

    if (ScraperWiki.select("* from data where `council_reference`='#{application[:council_reference]}'").empty? rescue true)
      ScraperWiki.save_sqlite([:council_reference], application)
    else
      puts "Skipping already saved record " + application[:council_reference]
    end
  end
end

save_applications @agent.get(url)

# TODO: Iterate through pagination
