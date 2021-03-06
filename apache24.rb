require 'fileutils'
require 'formula'

class Apache24 < Formula
  homepage 'https://httpd.apache.org/'
  url 'http://mirrors.digipower.vn/apache/httpd/httpd-2.4.9.tar.gz'
  sha1 '50496e51605a3d852c183a7c667c25bcc7ee658d'

  skip_clean ['bin', 'sbin', 'logs']

  depends_on 'pcre'
  depends_on 'lua' => :optional

  conflicts_with 'apache22',
    :because => "apache24 and apache22 install the same binaries."

  # Apache 2.4 no longer bundles apr or apr-util so we have to fetch
  # it manually for each build
  def fetch_apr
    ["apr-1.5.1", "apr-util-1.5.3"].each do |tb|
      curl "-s", "-o", "#{tb}.tar.gz", "https://www.apache.org/dist/apr/#{tb}.tar.gz"
      system "tar -xzf #{tb}.tar.gz"
      dir = tb.rpartition('-')[0]
      FileUtils.mv(tb, "srclib/#{dir}")
    end
  end

  def install
    fetch_apr

    # install custom layout
    File.open('config.layout', 'w') { |f| f.write(apache_layout) };

    args = [
      "--prefix=#{prefix}",
      "--mandir=#{man}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-mpm=prefork",
      "--with-included-apr",
      "--enable-mods-shared=all",
      "--with-pcre=#{Formula.factory('pcre').prefix}",
      "--enable-layout=Homebrew"
    ]
    args << "--enable-lua" if build.with? 'lua'

    p './configure ' + args.join(' ')
    system './configure', *args
    system "make"
    system "make install"

    # create logs directory
    FileUtils.mkdir_p "#{var}/log/apache2"
  end

  def apache_layout
    return <<-EOS.undent
      <Layout Homebrew>
          prefix:        #{prefix}
          exec_prefix:   ${prefix}
          bindir:        ${exec_prefix}/bin
          sbindir:       ${exec_prefix}/bin
          libdir:        ${exec_prefix}/lib
          libexecdir:    #{lib}/apache2/modules
          mandir:        #{man}
          sysconfdir:    #{etc}/apache2
          datadir:       ${prefix}
          installbuilddir: ${datadir}/build
          errordir:      #{var}/apache2/error
          iconsdir:      #{var}/apache2/icons
          htdocsdir:     #{var}/apache2/htdocs
          manualdir:     #{doc}/manual
          cgidir:        #{var}/apache2/cgi-bin
          includedir:    ${prefix}/include
          localstatedir: #{var}/apache2
          runtimedir:    #{var}/log/apache2
          logfiledir:    #{var}/log/apache2
          proxycachedir: ${localstatedir}/proxy
      </Layout>
      EOS
  end

  plist_options :manual => "sudo apachectl start"

  def plist_startup
    true
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_prefix}/bin/httpd</string>
        <string>-D</string>
        <string>FOREGROUND</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>SHAuthorizationRight</key>
      <string>system.preferences</string>
    </dict>
    </plist>
    EOS
  end
end
