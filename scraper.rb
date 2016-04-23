require 'mechanize'
require 'scraperwiki'

@agent = Mechanize.new
url = 'http://datrack.canterbury.nsw.gov.au/cgi/datrack.pl?search=search'

def save_applications(application_list)
  application_list.search('.datrack_resultrow_odd,.datrack_resultrow_even').each do |row|
    council_reference = row.at(:a).inner_text
    if !(ScraperWiki.select("* from swdata where `council_reference`='#{council_reference}'").empty? rescue true)
      puts "Skipping already saved record #{council_reference}"
      next
    end

    info_url = row.at(:a).attr(:href)
    day, month, year = row.at('.datrack_lodgeddate_cell').inner_text.split('/').map { |n| n.to_i }
    address = row.at('.datrack_houseno_cell').inner_text + ' ' +
              row.at('.datrack_street_cell').inner_text + ', ' +
              row.at('.datrack_town_cell').inner_text + ' NSW'

    detail_page = @agent.get info_url

    application = {
      council_reference: council_reference,
      address: address,
      description: detail_page.at('.wh_preview_master').search(:td)[1].inner_text,
      info_url: info_url,
      comment_url: 'mailto:council@canterbury.nsw.gov.au',
      date_scraped: Date.today,
      date_received: Date.new(year, month, day)
    }

    ScraperWiki.save_sqlite([:council_reference], application)
  end
end

puts 'Getting first page'
application_list = @agent.get(url)
save_applications application_list

pageno = 1
while application_list.link_with(text: 'Next')
  puts 'Getting next page ' + pageno.to_s
  application_list = application_list.link_with(text: 'Next').click
  save_applications application_list
  pageno += 1
end
