<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8"/>
    <title>simple-bank-balance</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

    <script>
    $(document).ready(function(){
        var getRequest;

        getRequest = $.ajax({
            url: 'v1/controller/balance.php',
            type: 'GET',
            dataType: 'JSON'
        });

        getRequest.done(function (response, textStatus, jqXHR){
            $("#balanceTable tbody").html("");
            var len = response.data.length;
            for(var i=0; i<len; i++){
              var balance = response.data[i].balance;
              var id = response.data[i].id;
              var database = response.data[i].frontend;
              var frontend = response.data[i].frontend;
              var backend = response.data[i].backend;

              var tr_str = "<tr>" +
              "<td>" + id + "</td>" +
              "<td>" + balance + "</td>" +
                  "</tr>";

              $("#balanceTable tbody").append(tr_str);
              $("#read-path").html("<br>Database Server:  " + database + "<br>Backend Server:" + backend + "<br>Frontend Server:" + frontend);
            }
        });

        $("#balance-form").submit(function(event){
            var postRequest;
            event.preventDefault();

            var $form = $(this);
            var serializedData = $form.serialize();
            console.log(serializedData);

            var $inputs = $form.find("input, button");  
            $inputs.prop("disabled", true);

            postRequest = $.ajax({
                url: "/v1/controller/balance.php",
                type: "POST",
                data: serializedData
            });

            postRequest.done(function (response, textStatus, jqXHR){
                var getRequest;
                getRequest = $.ajax({
                    url: 'v1/controller/balance.php',
                    type: 'GET',
                    dataType: 'JSON'
                });

                getRequest.done(function (response, textStatus, jqXHR){
                  $("#balanceTable tbody").html("");
                  $("#balance-form")[0].reset();
                  var len = response.data.length;
                  for(var i=0; i<len; i++){
                    var balance = response.data[i].balance;
                    var id = response.data[i].id;
                    var database = response.data[i].frontend;
                    var frontend = response.data[i].frontend;
                    var backend = response.data[i].backend;

                    var tr_str = "<tr>" +
                    "<td>" + id + "</td>" +
                    "<td>" + balance + "</td>" +
                        "</tr>";

                    $("#balanceTable tbody").append(tr_str);
                    $("#read-path").html("<br>Database Server:  " + database + "<br>Backend Server:" + backend + "<br>Frontend Server:" + frontend);
                  }
                });

                getRequest.fail(function (jqXHR, textStatus, errorThrown){
                    console.error(
                        "The following error occurred: "+
                        textStatus, errorThrown
                    );
                });
            });

            postRequest.fail(function (jqXHR, textStatus, errorThrown){
                console.error(
                    "The following error occurred: "+
                    textStatus, errorThrown
                );
            });

            postRequest.always(function () {
                $inputs.prop("disabled", false);
            });

        });

        $("#result-form").submit(function(event){
            var postRequest;
            event.preventDefault();

            var getRequest;
            getRequest = $.ajax({
                url: 'v1/controller/balance.php',
                type: 'GET',
                dataType: 'JSON'
            });

            getRequest.done(function (response, textStatus, jqXHR){
                $("#balanceTable tbody").html("");
                $("#balance-form")[0].reset();
                var len = response.data.length;
                for(var i=0; i<len; i++){
                    var balance = response.data[i].balance;
                    var id = response.data[i].id;
                    var database = response.data[i].frontend;
                    var frontend = response.data[i].frontend;
                    var backend = response.data[i].backend;

                    var tr_str = "<tr>" +
                    "<td>" + id + "</td>" +
                    "<td>" + balance + "</td>" +
                        "</tr>";

                    $("#balanceTable tbody").append(tr_str);
                    $("#read-path").html("<br>Database Server:  " + database + "<br>Backend Server:" + backend + "<br>Frontend Server:" + frontend);
                  }
            });

            getRequest.fail(function (jqXHR, textStatus, errorThrown){
                console.error(
                    "The following error occurred: "+
                    textStatus, errorThrown
                );
            });
        });

    });
    </script>
</head>

<body>
    <div class="container">
        <h2>Input Form</h2>
        <p>The balance information is sent to the backend database following this path: <strong>Web Application --> PHP API --> GraphQL API --> Database</strong></p>
        <form id="balance-form" action="" method="post">
            <div class="form-group">
                <label for="balance">Balance:</label>
                <input type="text" name="balance" class="form-control" id="balance">
            </div>
            <button type="submit" name="submit" class="btn btn-default">Submit</button>
        </form>

        <h2>Output Table</h2>
        <p>The information presented in the table below is received following this path: <strong><div id="read-path"></div></strong></p>
        <form id="result-form" action="" method="post">
            <button type="submit" name="read" class="btn btn-default">Read Backend</button>
        </form>
        <table id="balanceTable" class="table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Balance</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
    </div>

</body>

</html>