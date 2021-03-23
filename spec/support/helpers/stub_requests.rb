def stub_redcap_api_record_request(body:)
  stub_request(:post, "https://redcap.nubic.northwestern.edu/redcap/api/").
    with(
      body: {
        token: project.api_token,
        content: 'record',
        format: 'json',
        returnFormat: 'json',
        type: 'flat'
      }
    ).to_return(status: 200, body: body, headers: {}
  )
end

def stub_redcap_api_metadata_request(body:)
  stub_request(:post, "https://redcap.nubic.northwestern.edu/redcap/api/").
    with(
      body: {
        token: project.api_token,
        content: 'metadata',
        format: 'json',
        returnFormat: 'json'
      }
    ).to_return(status: 200, body: body, headers: {}
  )
end

