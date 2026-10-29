[
  {
    resource = "http://localhost:1997/tom";
    scan_interval = "300";
    sensor = [
      {
        name = "toms.spendable";
        value_template = "{{ value_json.spendable }}";
      }
    ];
  }
  {
    resource = "http://localhost:1997/kelsey";
    scan_interval = "300";
    sensor = [
      {
        name = "kelseys.spendable";
        value_template = "{{ value_json.spendable }}";
      }
    ];
  }
  {
    resource = "http://localhost:1997/joint";
    scan_interval = "300";
    sensor = [
      {
        name = "joint.spendable";
        value_template = "{{ value_json.spendable }}";
      }
    ];
  }
]
