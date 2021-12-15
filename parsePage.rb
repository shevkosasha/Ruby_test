require 'net/http'
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'csv'

# function for product page parsing
def parseProduct(url, filename)

    page = Nokogiri::HTML(URI.open(url))

    # getting of common info: product name, image, available variations
    # path to info elements
    productNamePath = '//*[@class="product_main_name"]'
    variationsListPath = '//*[@id="attributes"]/fieldset/div/ul/li'
    imgPath = '//*[@id="bigpic"]'

    # info
    productName = page.xpath(productNamePath).text.strip
    imgSrc = page.xpath(imgPath).attr('src').to_s
    variationsList = page.xpath(variationsListPath)

    # array for product variations info
    variations = Array.new 
    for i in 0...variationsList.length
        itemNum = i+1
        # getting of quantity and price options
        quantityPath = variationsListPath + '[' + itemNum.to_s + ']/label/span[1]'
        pricePath = variationsListPath + '[' + itemNum.to_s + ']/label/span[2]'
        quantity = page.xpath(quantityPath).text.strip
        price = page.xpath(pricePath).text.strip

        # save options' info into array
        variations[i] = {:quantity => quantity, :price => price}
        # puts variations[i]          
    end

    # # saving into file
    CSV.open(filename, "ab") do |csv|
        variations.each do |item|
            if item.empty? 
                next
            else 
                itemHash = item
                name = productName + ' - ' + itemHash[:quantity]
                price = itemHash[:price]
                csv << [name,price,imgSrc]
            end       
        end 
    end
end


# function for page parsing
def parsePage(url, filePath)
    
    urlCurrent = url
     # array for product links
    linksArr = Array.new
    # path to a product link 
    linkPath = '//*[@id="product_list"]/li/div[1]/div[2]/div[2]/a' 
    # loop for pagination
    pageNum = 1
    code = '200'    
    loop do
        if pageNum > 1
            urlCurrent = url + '?p=' + pageNum.to_s
        end

        page = Nokogiri::HTML(URI.open(urlCurrent))
        uri = URI(urlCurrent)
        response  = Net::HTTP.get_response(uri)
        code = response.code 
        # if code != 200 break loop, else get links and save to array
        break if code != '200'

        links = page.xpath(linkPath)
        linksArr.push(links)
        # increment page number for the next loop iteration
        pageNum += 1        
    end

    puts linksArr.length

    #create a csv file
    CSV.open(filePath, "w") do |csv|
        csv << ["Name", "Price",'Image']   
    end
    #loop for each product page parsing
    linksArr.each do |arr|
        arr.each do |link|
            href = link.attr('href')
            parseProduct(href, filePath)
        end
    end

end


url = nil;
filePath = nil;

if ARGV.length > 0
    for arg in ARGV
        if arg.include? "-url:"
            index = arg.index(":")
            url = arg[index + 1, arg.length]
            # url = arg.delete_prefix('-url:')
        elsif arg.include? "-file:"
            index =  arg.index(":")
            filePath = arg[index + 1, arg.length]
            # filePath = arg.delete_prefix('-file:')
        else 
            puts 'args does not contain url and/or destination file'
        end    
    end
end

puts "page: #{url}"
puts "file path: #{filePath}"

# parsePage(url, filePath)
if url.nil? || filePath.nil? 
    puts 'Enter url and/or file path'
else
    puts 'start parsing'
    parsePage(url, filePath)
end