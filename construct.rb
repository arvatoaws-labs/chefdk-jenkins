#!/opt/bitnami/ruby/bin/ruby

require 'json'
require 'fileutils'
require 'git'
require 'berkshelf'

# TODO: is this really necessary? FileUtils.rm_rf('export')

in_place = {}
Dir.glob('data_bags/*/*.json') do |data_bag_plain|
  in_place[data_bag_plain] = false
end

Dir.glob('environments/*.json') do |e|
  environment = e.split('/')[1].split('.')[0]
  puts "\nWorking on #{environment} stored in file #{e}"
  environment_file = JSON.parse(File.read(e))
  cookbook_versions = environment_file['cookbook_versions']

  FileUtils.mkdir_p("export/#{environment}")

  berksfile_raw = File.readlines('Berksfile')

  cookbook_versions.each do |key, value|
    line = nil
    berksfile_raw.each_index do |idx|
      next unless berksfile_raw[idx].start_with?('cookbook', 'company_cookbook', 'customer_cookbook')
      next unless berksfile_raw[idx].split(/\s/)[1].split("'")[1] == key
      line = idx
      break
    end
    if line.nil?
      if key.start_with?('asy-')
        if value.start_with?('=')
          tag = value.gsub(/=\s*([0-9\.]*)/, '\1')
        elsif value.start_with?('~>')
          # TODO: git: find newest tag
          tag = value.gsub(/~>\s*([0-9\.]*)/, '\1')
        else
          raise "Unknown version constraint #{value}"
        end
        berksfile_raw.push("company_cookbook '#{key}', '#{value}', tag: \"v#{tag}\"")
      else
        berksfile_raw.push("cookbook '#{key}', '#{value}'")
      end
    else
      # TODO: FIX explicit branch
      if berksfile_raw[line].include?('branch:')
        berksfile_raw[line] = berksfile_raw[line].strip.split(',').reject { |elem| elem.include?('branch:') }.join(',')
      end
      bsp = berksfile_raw[line].strip.split('git:')
      if bsp.length == 2
        if value.start_with?('=')
          tag = value.gsub(/=\s*([0-9\.]*)/, '\1')
        elsif value.start_with?('~>')
          # TODO: git: find newest tag
          tag = value.gsub(/~>\s*([0-9\.]*)/, '\1')
        else
          raise "Unknown version constraint #{value}"
        end
        berksfile_raw[line] = "#{bsp[0]}'#{value}', git:#{bsp[1]}, tag: \"v#{tag}\""
      elsif bsp.length == 1
        if berksfile_raw[line].start_with?('company_cookbook', 'customer_cookbook')
          if value.start_with?('=')
            tag = value.gsub(/=\s*([0-9\.]*)/, '\1')
          elsif value.start_with?('~>')
            # TODO: git: find newest tag
            tag = value.gsub(/~>\s*([0-9\.]*)/, '\1')
          else
            raise "Unknown version constraint #{value}"
          end
          berksfile_raw[line] = "#{bsp[0]}, '#{value}', tag: \"v#{tag}\""
        else
          berksfile_raw[line] = "#{bsp[0]}, '#{value}'"
        end
      else
        raise "Parse error in Berksfile line #{line}: multiple git: entries found, must be 0 or 1"
      end
    end
  end
  File.open("export/#{environment}/Berksfile", 'w') do |f|
    berksfile_raw.each { |line| f.puts(line) }
  end

  berksfile = ::Berkshelf::Berksfile.from_file("export/#{environment}/Berksfile")
  berksfile.install
  berksfile.lockfile.save

  Dir.chdir('export') do
    Dir.chdir(environment) do
      ::Berkshelf.ui.mute do
        berksfile.vendor('cookbooks')
      end
      `find cookbooks | grep "/test/integration/" | xargs rm -fr`
      `rsync -av ../../environments .`
      # if File.exist?('../../.chef/encrypted_data_bag_secret')
      #   Dir.glob('../../data_bags/*/*.json') do |data_bag_plain|
      #     dbp_segments = data_bag_plain.split('/')
      #     FileUtils.mkdir_p(dbp_segments[2..-2].join('/'))
      #     new_file = dbp_segments[2..-1].join('/')
      #     if in_place[new_file]
      #       FileUtils.cp(data_bag_plain, new_file)
      #     else
			# 			# system("cat", data_bag_plain, out: $stdout, err: :out)
      #       puts "Encrypting #{data_bag_plain}"
      #       `knife data bag from file #{dbp_segments[3]} #{data_bag_plain} -z --secret-file ../../.chef/encrypted_data_bag_secret`
      #       puts "Encryption done"
      #       unless File.exist?(new_file)
      #         in_place[new_file] = true
      #         FileUtils.cp(data_bag_plain, new_file)
      #       end
			# 			# system("cat", new_file, out: $stdout, err: :out)
      #     end
      #   end
      # else
      #   raise("encrypted_data_bag_secret is missing")
      #   # `rsync -av ../../data_bags .` if Dir.exist?('../../data_bags')
      # end
      `rsync -av ../../roles .` if Dir.exist?('../../roles')
      `rsync -av ../../nodes .` if Dir.exist?('../../nodes')
      Dir.glob('../../site-cookbooks/*') do |site_cookbook|
        cookbook_name = site_cookbook.split('/')[-1]
        throw 'Site cookbook would overwrite normal cookbook, cowardly refusing' if Dir.exist?("cookbooks/#{cookbook_name}")
        `rsync -av #{site_cookbook} cookbooks/#{cookbook_name}`
      end
    end
    `tar -cjf #{environment}.tbz #{environment}`
  end
end
