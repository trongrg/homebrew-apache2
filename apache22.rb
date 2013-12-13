require 'fileutils'
require 'formula'

class Apache22 < Formula
  homepage 'https://httpd.apache.org/'
  url 'http://mirror.cc.columbia.edu/pub/software/apache/httpd/httpd-2.2.26.tar.gz'
  sha1 'dae47436517917b95f7ad58b33de1e6ff2471cae'

  skip_clean ['bin', 'sbin', 'logs']

  conflicts_with 'apache24',
    :because => "apache22 and apache24 install the same binaries."

  def install
    args = [
      "--prefix=#{prefix}",
      "--mandir=#{man}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-mpm=prefork",
      "--with-included-apr",
      "--enable-mods-shared=all",
      "--enable-proxy",
      "--enable-ssl",
    ]
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
        <string>FORGROUND</string>
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
