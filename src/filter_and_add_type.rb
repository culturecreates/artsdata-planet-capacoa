require 'json'

org_count = 0
person_count = 0

def safe_get(usermeta, key)
  value = usermeta[key] || {}
  value == "" ? {} : value
end

def get_type(user)
  usermeta = user['usermeta'] || {}

  operating_name1 = (usermeta['operating_name1'] || '').strip
  pmpro_approval_13 = safe_get(usermeta, 'pmpro_approval_13')
  pmpro_approval_12 = safe_get(usermeta, 'pmpro_approval_12')


  is_org = operating_name1 != ''
  is_ind = pmpro_approval_12['status'] == 'approved'
  is_indlife = pmpro_approval_13['status'] == 'approved'

  # if the user is not an organization or individual, skip
  return [nil, nil, true] unless is_org || is_ind || is_indlife

  # remove users who do not agree to terms and conditions 
  terms_conditions = safe_get(usermeta, 'terms_conditions')
  return [nil, nil, true] if terms_conditions == 'do not agree (v1.1)'

  member_type = if is_org
                  'organization'
                elsif is_indlife
                  'indlife'
                elsif is_ind
                  'ind'
                else
                  'organization'
                end

  schema_type =  is_org ? 'Organization' : 'Person'

  [member_type, schema_type, false]
end

members = JSON.parse(File.read("members.json", encoding: "utf-8"))
members_with_type = []

members.each do |member|
  member_type, schema_type, skip = get_type(member)
  next if skip

  member["member_type"] = member_type
  member["schema_type"] = schema_type
  # set empty fields to "empty" if they are blank
  empty_fields = ["charitable_status", "legal_form", "terms_conditions", "presenting_format"]
  for field in empty_fields
    member["usermeta"][field] = "empty" if member["usermeta"][field] == ""
  end

  org_count += 1 if schema_type == 'Organization'
  person_count += 1 if schema_type == 'Person'

  members_with_type << member
end

File.open("members.json", "w:UTF-8") do |f|
  f.write(JSON.pretty_generate(members_with_type))
end

puts "Processed #{members_with_type.length} members."
puts "Total organizations: #{org_count}"
puts "Total individuals: #{person_count}"
