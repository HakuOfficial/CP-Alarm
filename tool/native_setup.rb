require 'xcodeproj'
require 'fileutils'
require 'rexml/document'
require 'rexml/formatters/default'

# Work only in the freshly-created Flutter iOS host in this project's directory.
root = File.expand_path('..', __dir__)
Dir.chdir(root)
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |t| t.name == 'Runner' }
group = project.main_group.find_subpath('Runner', true)
FileUtils.cp('ios_src/AppDelegate.swift', 'ios/Runner/AppDelegate.swift')
%w[Radar.wav Apex.wav].each do |name|
  FileUtils.cp("ios_src/#{name}", "ios/Runner/#{name}")
  ref = group.files.find { |f| f.path == name } || group.new_file(name)
  runner.resources_build_phase.add_file_reference(ref, true)
end
bundle = ENV.fetch('BUNDLE_ID', 'com.kuda.cpalarm')
project.build_configurations.each { |cfg| cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0' }
project.targets.each do |target|
  target.build_configurations.each do |cfg|
    cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    next unless target == runner
    cfg.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle
    if ENV['APPLE_TEAM_ID'] && !ENV['APPLE_TEAM_ID'].empty?
      cfg.build_settings['DEVELOPMENT_TEAM'] = ENV.fetch('APPLE_TEAM_ID')
    end
    if cfg.name == 'Release' && ENV['PROFILE_NAME'] && !ENV['PROFILE_NAME'].empty?
      cfg.build_settings.merge!('CODE_SIGN_STYLE'=>'Manual','CODE_SIGN_IDENTITY'=>'Apple Distribution','PROVISIONING_PROFILE_SPECIFIER'=>ENV.fetch('PROFILE_NAME'))
    end
  end
end
project.save
info = 'ios/Runner/Info.plist'
plist = Xcodeproj::Plist.read_from_path(info)
plist.merge!('CFBundleDisplayName'=>'CP Alarm','CFBundleName'=>'CP Alarm','CFBundleDevelopmentRegion'=>'vi','NSAlarmKitUsageDescription'=>'CP Alarm cần đặt báo thức cho buổi luyện và contest, kể cả khi iPhone đang ở chế độ Tập trung.')
Xcodeproj::Plist.write_to_path(plist, info)
assets = 'ios/Runner/Assets.xcassets'
FileUtils.cp_r('ios_src/AppIcon.appiconset/.', "#{assets}/AppIcon.appiconset")
launch = "#{assets}/LaunchImage.imageset"
FileUtils.mkdir_p(launch)
FileUtils.cp_r('ios_src/LaunchImage.imageset/.', launch)
story = 'ios/Runner/Base.lproj/LaunchScreen.storyboard'
doc = REXML::Document.new(File.read(story))
REXML::XPath.each(doc, '//color[@key="backgroundColor"]') do |color|
  color.attributes.delete('white')
  {'red'=>'0.039216','green'=>'0.043137','blue'=>'0.054902','alpha'=>'1','colorSpace'=>'custom','customColorSpace'=>'sRGB'}.each { |k,v| color.attributes[k]=v }
end
File.open(story,'w') { |f| REXML::Formatters::Default.new.write(doc,f) }
podfile = 'ios/Podfile'
if File.exist?(podfile)
  src = File.read(podfile)
  src.sub!(/^\s*#?\s*platform :ios,.*$/, "platform :ios, '17.0'") || src.prepend("platform :ios, '17.0'\n")
  File.write(podfile,src)
end
