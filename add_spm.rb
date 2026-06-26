require 'xcodeproj'

project_path = 'CockpitComponentDemo.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check if already added
local_pkg_ref = project.root_object.package_references.find { |p| p.path == 'Packages/SevereWeatherShared' }
unless local_pkg_ref
    local_pkg_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
    local_pkg_ref.path = 'Packages/SevereWeatherShared'
    project.root_object.package_references << local_pkg_ref
end

pkg_product = target.package_product_dependencies.find { |p| p.product_name == 'SevereWeatherShared' }
unless pkg_product
    pkg_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    pkg_product.package = local_pkg_ref
    pkg_product.product_name = 'SevereWeatherShared'
    target.package_product_dependencies << pkg_product
end

# Now add it to the Frameworks build phase
frameworks_phase = target.frameworks_build_phase
# Check if already in build phase
build_file = frameworks_phase.files.find { |f| f.product_ref == pkg_product }
unless build_file
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = pkg_product
    frameworks_phase.files << build_file
end

project.save
puts "Successfully linked SevereWeatherShared to target."
