require "net/http"
require "uri"

# Downloads a PDF from a link (Google Drive share links included) so it can
# be stored in the database and served by the API.
#
#   bytes = RemotePdf.fetch("https://drive.google.com/file/d/ID/view")
#
# Raises RemotePdf::Error with a readable message when it cannot.
class RemotePdf
  class Error < StandardError; end

  MAX_BYTES     = 25.megabytes
  MAX_REDIRECTS = 6
  TIMEOUT       = 40

  # Google Drive file id from the usual link shapes, or nil
  def self.drive_id(url)
    url = url.to_s
    url[%r{drive\.google\.com/file/d/([\w-]+)}, 1] ||
      url[%r{docs\.google\.com/(?:uc|open)\?(?:.*&)?id=([\w-]+)}, 1] ||
      url[%r{drive\.google\.com/(?:uc|open)\?(?:.*&)?id=([\w-]+)}, 1] ||
      url[%r{drive\.usercontent\.google\.com/download\?(?:.*&)?id=([\w-]+)}, 1]
  end

  # Direct-download address for a link (Drive links are rewritten)
  def self.download_url(url)
    id = drive_id(url)
    id ? "https://drive.usercontent.google.com/download?id=#{id}&export=download&confirm=t" : url.to_s
  end

  # Address that shows the file in Google's viewer (Drive only), else the link itself
  def self.preview_url(url)
    id = drive_id(url)
    id ? "https://drive.google.com/file/d/#{id}/preview" : url.to_s
  end

  def self.fetch(url)
    new.fetch(download_url(url))
  end

  def fetch(url, redirects = 0)
    raise Error, "No link to download from" if url.blank?
    raise Error, "Too many redirects" if redirects > MAX_REDIRECTS

    uri = URI.parse(url)
    raise Error, "Link must start with http:// or https://" unless uri.is_a?(URI::HTTP)

    response = get(uri)
    case response
    when Net::HTTPRedirection
      fetch(URI.join(uri.to_s, response["location"]).to_s, redirects + 1)
    when Net::HTTPSuccess
      body = response.body.to_s.b
      return body if body.start_with?("%PDF")

      # Drive shows a "can't scan for viruses" page for larger files: follow its form
      next_url = drive_confirm_url(body)
      return fetch(next_url, redirects + 1) if next_url && redirects < MAX_REDIRECTS

      if body.include?("ServiceLogin") || body.include?("accounts.google.com")
        raise Error, "The file is private. In Google Drive set it to \"Anyone with the link\" and try again."
      end
      raise Error, "The link did not return a PDF"
    else
      raise Error, "Download failed (HTTP #{response.code})"
    end
  rescue URI::InvalidURIError
    raise Error, "That is not a valid link"
  rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout
    raise Error, "The link took too long to answer. Try again in a moment."
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, SocketError, OpenSSL::SSL::SSLError
    raise Error, "Could not reach the link. Check the server's internet connection and that the link is correct."
  end

  private

  def get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 15, read_timeout: TIMEOUT) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "HoneysuckleMenuFetcher/1.0"
      http.request(request) do |res|
        next unless res.is_a?(Net::HTTPSuccess)

        size = res["content-length"].to_i
        raise Error, "File is larger than #{MAX_BYTES / 1.megabyte} MB" if size > MAX_BYTES

        buffer = +""
        res.read_body do |chunk|
          buffer << chunk
          raise Error, "File is larger than #{MAX_BYTES / 1.megabyte} MB" if buffer.bytesize > MAX_BYTES
        end
        res.instance_variable_set(:@body, buffer)
        res.instance_variable_set(:@read, true)
      end
    end
  end

  def drive_confirm_url(html)
    text = html.dup.force_encoding("UTF-8").scrub
    action = text[/<form[^>]+action="([^"]+)"/, 1]
    return nil unless action&.include?("drive.usercontent.google.com")

    fields = text.scan(/<input[^>]+type="hidden"[^>]+name="([^"]+)"[^>]+value="([^"]*)"/)
    return nil if fields.empty?

    "#{CGI.unescapeHTML(action)}?#{URI.encode_www_form(fields.map { |k, v| [ k, CGI.unescapeHTML(v) ] })}"
  end
end
